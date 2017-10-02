#!/bin/bash

WORKSPACE="${HOME}/workspace"
CF_DEPLOYMENT_REPO="${WORKSPACE}/cf-deployment"
PERM_CI_REPO="${WORKSPACE}/perm-ci"
CAPI_CI_REPO="${WORKSPACE}/capi-ci"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/capi.sh"
# shellcheck source=/dev/null
source "${CWD}/perm.sh"

function deploy_cf() (
  set -eu

  local bosh_deployment="${BOSH_DEPLOYMENT:-cf}"
  local system_domain="${SYSTEM_DOMAIN:-"${BOSH_LITE_DOMAIN}"}"
  local perm_version="${PERM_VERSION:-latest}"

  : "${BOSH_ENVIRONMENT:?"Need to set BOSH_ENVIRONMENT"}"
  : "${system_domain:?"Need to set SYSTEM_DOMAIN or BOSH_LITE_DOMAIN"}"

  BOSH_DEPLOYMENT="$bosh_deployment"

  bosh -n \
    deploy --skip-drain ~/workspace/cf-deployment/cf-deployment.yml \
    -v system_domain="$system_domain" \
    -v perm_version="$perm_version" \
    -o "${CF_DEPLOYMENT_REPO}/operations/bosh-lite.yml" \
    -o "${CF_DEPLOYMENT_REPO}/operations/bypass-cc-bridge.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-stemcell.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/skip-cert-verify.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-bpm.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/add-perm.yml" \
    -o "${PERM_CI_REPO}/cf-deployment-operations/minimal.yml" \
    -o "${CAPI_CI_REPO}/cf-deployment-operations/use-latest-capi.yml"
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
