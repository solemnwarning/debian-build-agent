terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "tls_private_key" "ssh_host_rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "tls_private_key" "ssh_host_ecdsa" {
  algorithm = "ECDSA"
}

resource "tls_private_key" "ssh_host_ed25519" {
  algorithm = "ED25519"
}

resource "libvirt_volume" "root" {
  name   = "debian-build-agent-${random_id.suffix.hex}.qcow2"
  pool   = var.storage_pool
  source = "file:/mnt/builds/debian-build-agent/latest/debian-build-agent.qcow2"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "cloud_init" {
  name = "debian-build-agent-${random_id.suffix.hex}.cloud-init.iso"
  pool = var.storage_pool

  user_data  = templatefile("user_data.tftpl", {
    buildkite_agent_token = var.buildkite_agent_token
    http_proxy_url        = var.http_proxy_url
    instance_id           = random_id.suffix.hex
    root_password         = var.root_password

    ssh_host_ecdsa   = tls_private_key.ssh_host_ecdsa
    ssh_host_ed25519 = tls_private_key.ssh_host_ed25519
    ssh_host_rsa     = tls_private_key.ssh_host_rsa
  })
}

resource "libvirt_domain" "debian-build-agent" {
  name    = "debian-build-agent-${random_id.suffix.hex}"
  memory  = "12288"
  vcpu    = 8
  running = false

  description = chomp(
    <<-EOT
    [buildkite-libvirt-scaler]
    buildkite-agent-meta-data = queue=linux-generic,queue=linux-debian
    buildkite-agent-spawn = 2
    EOT
  )

  cloudinit = "${libvirt_cloudinit_disk.cloud_init.id}"

  network_interface {
    bridge = "dmz-build"
  }

  disk {
    volume_id = "${libvirt_volume.root.id}"
  }
}
