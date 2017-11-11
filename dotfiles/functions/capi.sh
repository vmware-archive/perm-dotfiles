#!/bin/bash

CAPI_RELEASE_NAME="capi"

WORKSPACE="${HOME}/workspace"
CAPI_RELEASE_REPO="${WORKSPACE}/capi-release"
TMPDIR="${TMPDIR:-/tmp}"
CAPI_RELEASE_DIR="/${TMPDIR}/tmp-capi-release"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/bosh.sh"

# Because of CAPI's `pre_packaging` usage, we need to use a different bundle config
# for the release than we do for development :(
function create_capi_release_for_perm() (
  set -eu

  pushd "$CAPI_RELEASE_REPO" > /dev/null
    git pull -r
    "${CAPI_RELEASE_REPO}/scripts/update"
  popd > /dev/null

  rm -rf "$CAPI_RELEASE_DIR"
  cp -R "$CAPI_RELEASE_REPO" "$CAPI_RELEASE_DIR"

  # Ensures that version numbers are synced correctly
  symlink .dev_builds
  symlink dev_releases
  symlink .blobs
  symlink blobs

  mkdir -p "${CAPI_RELEASE_DIR}/src/cloud_controller_ng/.bundle"
  cat << EOF > "${CAPI_RELEASE_DIR}/src/cloud_controller_ng/.bundle/config"
---
BUNDLE_LOCAL__CF-PERM: "/Users/pivotal/workspace/perm-rb"
BUNDLE_CACHE_ALL_PLATFORMS: "true"
BUNDLE_CACHE_ALL: "true"

BUNDLE_SPECIFIC_PLATFORM: "false"
BUNDLE_NO_INSTALL: "true"
BUNDLE_PATH: "vendor/cache"
EOF

  RELEASE_NAME="$CAPI_RELEASE_NAME" RELEASE_DIR="$CAPI_RELEASE_DIR" create_release
)

function upload_capi_release_for_perm() (
  set -eu

  RELEASE_NAME="$CAPI_RELEASE_NAME" RELEASE_DIR="$CAPI_RELEASE_DIR" upload_release
)

function create_and_upload_capi_release_for_perm() (
  set -eu

  create_capi_release_for_perm
  upload_capi_release_for_perm
)

function symlink() {
  local dir="$1"

  mkdir -p "${CAPI_RELEASE_REPO}/${dir}"
  rm -rf "${CAPI_RELEASE_DIR:?}/${dir}"
  ln -s "${CAPI_RELEASE_REPO}/${dir}" "${CAPI_RELEASE_DIR}/${dir}"
}
