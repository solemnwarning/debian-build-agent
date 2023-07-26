terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

variable "buildkite_agent_token" {
  type = string
  sensitive = true
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

data "dns_srv_record_set" "apt_proxy" {
  service = "_apt_proxy._tcp.build.solemnwarning.net."
}

data "dns_srv_record_set" "http_proxy" {
  service = "_http_proxy._tcp.build.solemnwarning.net."
}

locals {
  apt_proxy_url  = "http://${data.dns_srv_record_set.apt_proxy.srv.0.target}:${data.dns_srv_record_set.apt_proxy.srv.0.port}/"
  http_proxy_url = "http://${data.dns_srv_record_set.http_proxy.srv.0.target}:${data.dns_srv_record_set.http_proxy.srv.0.port}/"
}

provider "libvirt" {
  uri = "qemu:///system"
  # uri = "qemu+ssh://root@ishikawa.solemnwarning.net/system?sshauth=privkey"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "libvirt_volume" "root" {
  name   = "debian-build-agent-${random_id.suffix.hex}.qcow2"
  pool   = "default"
  source = "file:/mnt/builds/debian-build-agent/latest/debian-build-agent.qcow2"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name       = "debian-build-agent-${random_id.suffix.hex}.cloud-init.iso"
  user_data  = templatefile("user_data.tftpl", {
    apt_proxy_url         = local.apt_proxy_url
    buildkite_agent_token = var.buildkite_agent_token
    http_proxy_url        = local.http_proxy_url
    instance_id           = random_id.suffix.hex
    root_password         = random_password.root_password
  })
}

resource "libvirt_domain" "debian-build-agent" {
  name   = "debian-build-${random_id.suffix.hex}"
  memory = "12288"
  vcpu   = 8

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  network_interface {
    bridge = "dmz-build"
  }

  disk {
    volume_id = "${libvirt_volume.root.id}"
  }
}
