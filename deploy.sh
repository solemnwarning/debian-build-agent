#!/bin/bash

set -e

cd "$(dirname "$0")/cluster/"

terraform init
terraform apply -auto-approve
