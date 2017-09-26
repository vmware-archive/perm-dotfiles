#!/bin/bash

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
