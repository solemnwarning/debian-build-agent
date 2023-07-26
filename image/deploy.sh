#!/bin/bash

BUILDS="/mnt/builds"

set -e

packer build debian-build-agent.pkr.hcl

version=$(date --utc '+%Y%m%d%H%M%S')

mkdir -p "${BUILDS}/debian-build-agent/"
cp -a "output" "${BUILDS}/debian-build-agent/debian-build-agent-${version}"
ln -sfn "debian-build-agent-${version}" "${BUILDS}/debian-build-agent/latest"
