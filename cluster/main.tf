terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

resource "random_password" "root_password" {
  length = 12

  # This is likely to be entered into the system console... a place where
  # keyboard layout mismatches or RDP/VNC weirdness will probably make special
  # characters hard/impossible to type.
  special = false
}

output root_password {
  value     = random_password.root_password.result
  sensitive = true
}

resource "tls_private_key" "buildkite_user_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output buildkite_user_public_ssh_key {
  value = tls_private_key.buildkite_user_ssh_key.public_key_openssh
}

provider "libvirt" {
  alias = "vmhost01"
  uri = "qemu:///system"
}

module "deploy_to_vmhost01" {
  source    = "./deploy_to_host/"
  providers = {
    libvirt = libvirt.vmhost01
  }

  buildkite_agent_token = var.buildkite_agent_token
  http_proxy_url = var.http_proxy_url
  root_password = random_password.root_password
  buildkite_user_ssh_key = tls_private_key.buildkite_user_ssh_key
}

provider "libvirt" {
  alias = "vmhost02"
  uri = "qemu+ssh://root@vmhost02.lan.solemnwarning.net/system?sshauth=privkey"
}

module "deploy_to_vmhost02" {
  source    = "./deploy_to_host/"
  providers = {
    libvirt = libvirt.vmhost02
  }

  buildkite_agent_token = var.buildkite_agent_token
  http_proxy_url = var.http_proxy_url
  root_password = random_password.root_password
  buildkite_user_ssh_key = tls_private_key.buildkite_user_ssh_key
}

provider "libvirt" {
  alias = "vmhost03"
  uri = "qemu+ssh://root@vmhost03.lan.solemnwarning.net/system?sshauth=privkey"
}

module "deploy_to_vmhost03" {
  source    = "./deploy_to_host/"
  providers = {
    libvirt = libvirt.vmhost03
  }

  buildkite_agent_token = var.buildkite_agent_token
  http_proxy_url = var.http_proxy_url
  root_password = random_password.root_password
  buildkite_user_ssh_key = tls_private_key.buildkite_user_ssh_key
}
