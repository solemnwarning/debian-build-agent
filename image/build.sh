#!/bin/bash

set -e

timestamp=$(date --utc '+%Y-%m-%dT%H:%M:%SZ')

cd "$(dirname "$0")"

packer init  -var "output_dir=output/${timestamp}" debian-build-agent.pkr.hcl
packer build -var "output_dir=output/${timestamp}" debian-build-agent.pkr.hcl
ln -snfv "${timestamp}" "output/latest"
