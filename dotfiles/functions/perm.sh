#!/bin/bash

PERM_RELEASE_NAME="perm"

WORKSPACE="${HOME}/workspace"
PERM_RELEASE_REPO="${WORKSPACE}/perm-release"

TMPDIR="${TMPDIR:-/tmp}"
PERM_CERTS_DIR="${TMPDIR}/perm-certs"
PERM_CA_PATH="${PERM_CERTS_DIR}/ca.crt"
PERM_TLS_CERT_PATH="${PERM_CERTS_DIR}/tls.crt"
PERM_TLS_KEY_PATH="${PERM_CERTS_DIR}/tls.key"

CWD="$(dirname -- "${0}")"

# shellcheck source=/dev/null
source "${CWD}/bosh.sh"
# shellcheck source=/dev/null
source "${CWD}/credhub.sh"

function create_perm_release() (
  set -eu

  RELEASE_NAME="$PERM_RELEASE_NAME" RELEASE_DIR="$PERM_RELEASE_REPO" create_release
)

function upload_perm_release() (
  set -eu

  RELEASE_NAME="$PERM_RELEASE_NAME" RELEASE_DIR="$PERM_RELEASE_REPO" upload_release
)

function create_and_upload_perm_release() (
  set -eu

  create_perm_release
  upload_perm_release
)

function make_perm_certs() (
  set -eu

  local ca_name="/perm/ca"
  local tls_cert_name="/perm/tls"

  rm -rf "$PERM_CERTS_DIR"
  mkdir -p "$PERM_CERTS_DIR"
  login_to_credhub

  credhub generate \
    --output-json \
    --name "$ca_name" \
    --type certificate \
    --is-ca \
    --common-name perm-ca > /dev/null
  credhub generate \
    --output-json \
    --name "$tls_cert_name" \
    --type certificate \
    --is-ca \
    --common-name localhost \
    --alternative-name 127.0.0.1 \
    --ext-key-usage client_auth \
    --ext-key-usage server_auth > /dev/null

  credhub get -n "$ca_name" --output-json | jq -re .value.certificate > "$PERM_CA_PATH"
  credhub get -n "$tls_cert_name" --output-json | jq -re .value.certificate > "$PERM_TLS_CERT_PATH"
  credhub get -n "$tls_cert_name" --output-json | jq -re .value.private_key > "$PERM_TLS_KEY_PATH"
)

function run_perm() (
  set -eu

  local log_level="${PERM_LOG_LEVEL:-info}"

  if [[ ! (-f "$PERM_CA_PATH" && -f "$PERM_TLS_CERT_PATH" && -f "$PERM_TLS_KEY_PATH") ]]; then
    make_perm_certs
  fi

  "${PERM_RELEASE_REPO}/bin/perm" \
    --log-level "$log_level" \
    --tls-certificate "$PERM_TLS_CERT_PATH" \
    --tls-key "$PERM_TLS_KEY_PATH"
)
