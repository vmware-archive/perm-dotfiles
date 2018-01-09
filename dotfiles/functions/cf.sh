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

  pushd "$CF_DEPLOYMENT_REPO" > /dev/null
    git pull -r
  popd > /dev/null

  bosh -n \
    deploy --skip-drain ~/workspace/cf-deployment/cf-deployment.yml \
    -v system_domain="$system_domain" \
    -v perm_version="$perm_version" \
    -o "${CF_DEPLOYMENT_REPO}/operations/workaround/undo-metron-add-on.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/skip-cert-verify.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-stemcell.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/experimental/enable-bpm.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/experimental/skip-consul-cell-registrations.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/experimental/skip-consul-locks.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/experimental/use-bosh-dns.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/experimental/disable-consul.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/workaround/reenable-consul-stub.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/bosh-lite.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/workaround/disable-consul-bosh-lite.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/use-compiled-releases.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-perm.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-perm-monitor-api-sidecar.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-cc-to-perm-migrator-errand.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-capi.yml" \
    "$@"
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
