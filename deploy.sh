#!/bin/bash

set -e

cd "$(dirname "$0")/cluster/"

powerwake -w 98:90:96:db:85:40
powerwake -w 64:00:6a:5d:b3:6e

terraform init
terraform apply -auto-approve \
	-replace=module.deploy_to_vmhost01.libvirt_volume.root \
	-replace=module.deploy_to_vmhost02.libvirt_volume.root \
	-replace=module.deploy_to_vmhost03.libvirt_volume.root
