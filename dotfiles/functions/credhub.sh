#!/bin/bash

function login_to_credhub() (
  set -eu

  : "${CREDHUB_SERVER:?"Need to set CREDHUB_SERVER"}"

  if [[ -n "${CREDHUB_CLIENT:-}" && -n "${CREDHUB_SECRET:-}" ]]; then
    credhub login --skip-tls-validation
  else
    : "${CREDHUB_USERNAME:?"Need to set CREDHUB_USERNAME"}"
    : "${CREDHUB_PASSWORD:?"Need to set CREDHUB_PASSWORD"}"

    credhub login --skip-tls-validation \
      --username "$CREDHUB_USERNAME" \
      --password "$CREDHUB_PASSWORD"
  fi
)
