#!/bin/bash

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/credhub.sh"

function create_release() (
  : "${RELEASE_NAME:?"Need to set RELEASE_NAME"}"
  : "${RELEASE_DIR:?"Need to set RELEASE_DIR"}"

  echo "Creating release ${RELEASE_NAME}"

  bosh --sha2 cr \
    --force \
    --name "$RELEASE_NAME" \
    --dir "$RELEASE_DIR"

  echo "Created release ${RELEASE_NAME}"
)

function upload_release() (
  set -eu

  : "${BOSH_ENVIRONMENT:?"Need to set BOSH_ENVIRONMENT"}"
  : "${RELEASE_DIR:?"Need to set RELEASE_DIR"}"
  : "${RELEASE_NAME:?"Need to set RELEASE_NAME"}"

  echo "Uploading release ${RELEASE_NAME}"

  bosh ur --dir "$RELEASE_DIR"

  echo "Uploaded release ${RELEASE_NAME}"
)

function target_ci_bosh_lite() {
  local env_name
  local temp_dir

  env_name="${1}"
  temp_dir="$(mktemp -d)"
  env_path="${temp_dir}/env.sh"

  echo "Writing target to ${env_path}"
  write_bosh_target "$env_name" "$temp_dir" "$env_path"
  exit_code="$?"

  if [[ "$exit_code" != "0" ]]; then
    echo "Failed :("
    return "$exit_code"
  fi

  # shellcheck source=/dev/null
  source "$env_path"
}

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

  local cf_deployed_successfully
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
  credhub_client="credhub-admin"
  credhub_secret="$(bosh interpolate "$creds_path" --path /credhub_admin_client_secret)"

  cf_username="admin"
  if cf_password="$(CREDHUB_CA_CERT="${credhub_ca}\n${uaa_ca}" CREDHUB_SERVER="$credhub_server" CREDHUB_CLIENT="$credhub_client" CREDHUB_SECRET="$credhub_secret" credhub get -n /bosh-lite/cf/cf_admin_password --output-json | jq -r -e .value)"; then
    cf_deployed_successfully="true"
  fi

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

  if [[  "${cf_deployed_successfully}" == "true" ]]; then
    echo -e "\033[32m\n## Target CF API and login as admin ##\033[0m"
    echo "cf_login"
  else
    echo -e "CF deployment failed\nCan't run \`cf_login\`"
  fi
)
