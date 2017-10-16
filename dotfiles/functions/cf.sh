#!/bin/bash

WORKSPACE="${HOME}/workspace"
CF_DEPLOYMENT_REPO="${WORKSPACE}/cf-deployment"
PERM_CI_REPO="${WORKSPACE}/perm-ci"
CAPI_CI_REPO="${WORKSPACE}/capi-ci"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/capi.sh"
# shellcheck source=/dev/null
source "${CWD}/credhub.sh"
# shellcheck source=/dev/null
source "${CWD}/perm.sh"

function deploy_cf() (
  set -eu

  local bosh_deployment="${BOSH_DEPLOYMENT:-cf}"
  local system_domain="${SYSTEM_DOMAIN:-"${BOSH_LITE_DOMAIN:-}"}"
  local perm_version="${PERM_VERSION:-latest}"

  : "${BOSH_ENVIRONMENT:?"Need to set BOSH_ENVIRONMENT"}"
  : "${system_domain:?"Need to set SYSTEM_DOMAIN or BOSH_LITE_DOMAIN"}"

  export BOSH_DEPLOYMENT="$bosh_deployment"

  bosh -n \
    deploy --skip-drain ~/workspace/cf-deployment/cf-deployment.yml \
    -v system_domain="$system_domain" \
    -v perm_version="$perm_version" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/skip-cert-verify.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-stemcell.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/use-compiled-releases.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/bosh-lite.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-bpm.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-perm.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-perm-monitor-api-sidecar.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-capi.yml"
)

function run_cats() (
  set -eu

  local admin_password
  local admin_username
  local config_file
  local system_domain
  local num_nodes

  num_nodes="${NUM_NODES:-20}"
  system_domain="${SYSTEM_DOMAIN:-"${BOSH_LITE_DOMAIN:-}"}"
  GOPATH="${GOPATH_GLOBAL:-"${GOPATH}"}"

  : "${system_domain:?"Need to set SYSTEM_DOMAIN or BOSH_LITE_DOMAIN"}"
  : "${GOPATH:?"Need to set GOPATH or GOPATH_GLOBAL"}"

  login_to_credhub

  admin_password="$(credhub get -n /bosh-lite/cf/cf_admin_password --output-json)"
  admin_password="$(echo "${admin_password}" | jq -r -e .value)"
  admin_username="admin"

  config_file="$(mktemp)"

  export GOPATH="$GOPATH"
  export CONFIG="$config_file"

  go get -u -d github.com/cloudfoundry/cf-acceptance-tests

  pushd "${GOPATH}/src/github.com/cloudfoundry/cf-acceptance-tests" > /dev/null
    "${PWD}/bin/update_submodules"

    cat > "$config_file" <<EOF
{
  "api": "api.${system_domain}",
  "apps_domain": "${system_domain}",
  "admin_user": "${admin_username}",
  "admin_password": "${admin_password}",
  "backend": "diego",
  "skip_ssl_validation": true,
  "use_http": false,
  "include_apps": true,
  "include_backend_compatibility": false,
  "include_capi_experimental": false,
  "include_capi_no_bridge": false,
  "include_container_networking": false,
  "include_credhub" : false,
  "include_detect": false,
  "include_docker": false,
  "include_internet_dependent": false,
  "include_isolation_segments": false,
  "include_persistent_app": false,
  "include_private_docker_registry": false,
  "include_privileged_container_support": false,
  "include_route_services": false,
  "include_routing": true,
  "include_routing_isolation_segments": false,
  "include_security_groups": false,
  "include_services": true,
  "include_ssh": false,
  "include_sso": false,
  "include_tasks": false,
  "include_v3": true,
  "include_zipkin": false
}
EOF

    "${PWD}/bin/test" -nodes="$num_nodes"
  popd > /dev/null
)

function upload_releases_and_deploy_cf() (
  set -eu

  create_and_upload_capi_release_for_perm
  create_and_upload_perm_release
  deploy_cf
)

function target_ci_bosh_lite() {
  local env_name
  local temp_dir

  env_name="${1}"
  temp_dir="$(mktemp -d)"
  env_path="${temp_dir}/env.sh"

  write_bosh_target "$env_name" "$temp_dir" "$env_path"

  # shellcheck source=/dev/null
  source "$env_path"
}

function delete_orgs() (
  set -eu

  echo "Warning! All of your orgs and everything in them will be deleted!"

  i=1

  cf orgs | while read -r line; do
    echo "$line"
    if [ $i -gt 3 ]; then
      cf delete-org -f "$line";
    fi
    ((i++))
  done
)

function write_bosh_target() (
  set -eu
  set -o pipefail

  local temp_dir
  local env_name
  local env_path
  local creds_path

  local bosh_ca_cert
  local bosh_admin_username
  local bosh_admin_password
  local bosh_ip
  local bosh_deployment
  local bosh_gw_user
  local bosh_gw_host
  local bosh_gw_private_key
  local bosh_gw_private_key_contents
  local bosh_lite_domain

  local uaa_ca

  local credhub_ca
  local credhub_server
  local credhub_username
  local credhub_password

  local cf_api
  local cf_username
  local cf_password

  env_name="${1}"
  temp_dir="${2}"
  env_path="${3}"
  creds_path="${temp_dir}/creds.yml"

  : "${env_name:?"Usage: \`target_ci_bosh_lite <env_name>\`"}"

  echo "Targeting environment ${env_name}..."

  gsutil cp "gs://perm-environments/director-state/${env_name}/creds.yml" "$creds_path" > /dev/null 2>&1

  bosh_lite_domain="${env_name}.perm.cf-app.com"
  cf_api="api.${bosh_lite_domain}"
  bosh_ip="$(dig +short "${cf_api}")"

  bosh_ca_cert="$(bosh interpolate "$creds_path" --path /default_ca/ca)"
  uaa_ca="${bosh_ca_cert}"

  bosh_admin_username="admin"
  bosh_admin_password="$(bosh interpolate "$creds_path" --path /admin_password)"
  bosh_deployment="cf"
  bosh_gw_user="jumpbox"
  bosh_gw_host="$bosh_ip"
  bosh_gw_private_key="${TMPDIR:-/tmp}/${env_name}.pem"
  bosh_gw_private_key_contents="$(bosh interpolate "$creds_path" --path /jumpbox_ssh/private_key)"

  credhub_ca="$(bosh interpolate "$creds_path" --path /credhub_ca/ca)"
  credhub_server="https://${bosh_ip}:8844"
  credhub_username="credhub-cli"
  credhub_password="$(bosh interpolate "$creds_path" --path /credhub_cli_password)"

  CREDHUB_CA_CERT="${credhub_ca}\n${uaa_ca}" \
    CREDHUB_SERVER="$credhub_server" \
    CREDHUB_USERNAME="$credhub_username" \
    CREDHUB_PASSWORD="$credhub_password" \
    login_to_credhub

  cf_username="admin"
  cf_password="$(credhub get -n /bosh-lite/cf/cf_admin_password --output-json | jq -r -e .value)"

  echo "$bosh_gw_private_key_contents" > "$bosh_gw_private_key"
  chmod 600 "$bosh_gw_private_key"

  cat << EOF > "$env_path"
export BOSH_CA_CERT="$bosh_ca_cert"
export BOSH_CLIENT="$bosh_admin_username"
export BOSH_CLIENT_SECRET="$bosh_admin_password"
export BOSH_ENVIRONMENT="$bosh_ip"
export BOSH_DEPLOYMENT="$bosh_deployment"
export BOSH_GW_USER="$bosh_gw_user"
export BOSH_GW_HOST="$bosh_gw_host"
export BOSH_GW_PRIVATE_KEY="$bosh_gw_private_key"
export BOSH_LITE_DOMAIN="$bosh_lite_domain"

function cf_login() {
  cf api "$cf_api" --skip-ssl-validation
  cf login -u "${cf_username}" -p "${cf_password}"
}
EOF

echo -e "\033[32m\n## Target CF API and login as admin ##\033[0m"
echo "cf_login"
)
