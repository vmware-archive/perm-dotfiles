#!/bin/bash

PERM_RELEASE_NAME="perm"

WORKSPACE="${HOME}/workspace"
PERM_RELEASE_REPO="${WORKSPACE}/perm-release"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/bosh.sh"

function create_perm_release() (
  set -eu

  RELEASE_NAME="$PERM_RELEASE_NAME" RELEASE_DIR="$PERM_RELEASE_REPO" create_release
)

function upload_perm_release() (
  set -eu

  RELEASE_DIR="$PERM_RELEASE_REPO" upload_release
)

function create_and_upload_perm_release() (
  set -eux

  create_perm_release
  upload_perm_release
)
