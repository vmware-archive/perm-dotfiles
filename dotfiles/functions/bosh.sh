#!/bin/bash

function create_release() (
  : "${RELEASE_NAME:?"Need to set RELEASE_NAME"}"
  : "${RELEASE_DIR:?"Need to set RELEASE_DIR"}"

  bosh --sha2 cr \
    --force \
    --name "$RELEASE_NAME" \
    --dir "$RELEASE_DIR"
)

function upload_release() (
  set -eu

  : "${BOSH_ENVIRONMENT:?"Need to set BOSH_ENVIRONMENT"}"
  : "${RELEASE_DIR:?"Need to set RELEASE_DIR"}"

  bosh ur --dir "$RELEASE_DIR"
)
