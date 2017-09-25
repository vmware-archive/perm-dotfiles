#!/bin/bash

CAPI_RELEASE_NAME="capi"

WORKSPACE="${HOME}/workspace"
CAPI_RELEASE_REPO="${WORKSPACE}/capi-release"
TMPDIR="${TMPDIR:-/tmp}"
CAPI_RELEASE_DIR="/${TMPDIR}/tmp-capi-release"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/bosh.sh"

function create_capi_release_for_perm() (
  set -eu

  rm -rf "$CAPI_RELEASE_DIR"
  cp -R "$CAPI_RELEASE_REPO" "$CAPI_RELEASE_DIR"

  mkdir -p "${CAPI_RELEASE_DIR}/src/cloud_controller_ng/.bundle"
  cat << EOF > "${CAPI_RELEASE_DIR}/src/cloud_controller_ng/.bundle/config"
---
BUNDLE_LOCAL__CF-PERM: "/Users/pivotal/workspace/perm-rb"
BUNDLE_CACHE_ALL_PLATFORMS: "true"
BUNDLE_CACHE_ALL: "true"

BUNDLE_SPECIFIC_PLATFORM: "false"
BUNDLE_NO_INSTALL: "true"
EOF

  RELEASE_NAME="$CAPI_RELEASE_NAME" RELEASE_DIR="$CAPI_RELEASE_DIR" create_release
)

function upload_capi_release_for_perm() (
  set -eu

  RELEASE_DIR="$CAPI_RELEASE_DIR" upload_release
)

function create_and_upload_capi_release_for_perm() (
  set -eu

  create_capi_release_for_perm
  upload_capi_release_for_perm
)
