#!/bin/bash

function upload_bpm_release() (
  set -eu

  bosh upload-release https://bosh.io/d/github.com/cloudfoundry-incubator/bpm-release
)
