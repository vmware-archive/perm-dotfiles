#!/bin/bash

function login_to_credhub() (
  set -eu

  CREDHUB_CA_CERT="${CREDHUB_CA_CERT:-}"

  : "${CREDHUB_SERVER:?"Need to set CREDHUB_SERVER"}"

  if [[ -z "$CREDHUB_CA_CERT" ]]; then
    SKIP_SSL_VALIDATION="true"
  fi

  if [[ -n "${CREDHUB_CLIENT:-}" && -n "${CREDHUB_SECRET:-}" ]]; then
    credhub login \
      "${CREDHUB_SERVER:+--server}" \
      "${CREDHUB_SERVER:+"${CREDHUB_SERVER}"}" \
      "${SKIP_SSL_VALIDATION:+--skip-tls-validation}"
  else
    : "${CREDHUB_USERNAME:?"Need to set CREDHUB_USERNAME"}"
    : "${CREDHUB_PASSWORD:?"Need to set CREDHUB_PASSWORD"}"

    credhub login \
      "${SKIP_SSL_VALIDATION:+--skip-tls-validation}" \
      "${CREDHUB_SERVER:+--server}" \
      "${CREDHUB_SERVER:+"${CREDHUB_SERVER}"}" \
      --username "$CREDHUB_USERNAME" \
      --password "$CREDHUB_PASSWORD"
  fi
)
