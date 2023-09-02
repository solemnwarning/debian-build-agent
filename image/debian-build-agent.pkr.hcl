packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "output_dir" {
  type    = string
  default = "output"
}

variable "ssh_password" {
  type    = string
  default = "root"
}

variable "http_proxy" {
  default = env("http_proxy")
}

variable "https_proxy" {
  default = env("https_proxy")
}

build {
  sources = ["source.qemu.debian"]

  provisioner "file" {
    sources = [
      "buildkite-agent.cfg",
      "buildkite-agent.gitconfig",
      "buildkite-agent.known_hosts",
      "buildkite-environment-hook",
    ]

    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      # Configure the APT proxy for downloading packages.

      "if [ -n \"${var.http_proxy}\" ]; then",
        "echo 'Acquire::http::Proxy \"${var.http_proxy}/\";' >> /etc/apt/apt.conf.d/proxy.conf",
      "fi",

      "if [ -n \"${var.https_proxy}\" ]; then",
        "echo 'Acquire::https::Proxy \"${var.https_proxy}/\";' >> /etc/apt/apt.conf.d/proxy.conf",
      "fi",

      # Install Buildkite agent

      "apt-get -y update",
      "apt-get -y install apt-transport-https dirmngr wget gpg gpg-agent",
      "https_proxy=\"${var.https_proxy}\" wget -O - https://keys.openpgp.org/vks/v1/by-fingerprint/32A37959C2FA5C3C99EFBC32A79206696452D198 | gpg --dearmor -o /etc/apt/trusted.gpg.d/buildkite-agent-keyring.gpg",
      "echo deb https://apt.buildkite.com/buildkite-agent stable main > /etc/apt/sources.list.d/buildkite-agent.list",

      "apt-get -y update",
      "apt-get -y install buildkite-agent",

      "install -m 0755 -o root -g root /tmp/buildkite-environment-hook /etc/buildkite-agent/hooks/environment",
      "install -m 0644 -o root -g root /tmp/buildkite-agent.cfg        /etc/buildkite-agent/buildkite-agent.cfg",
      "install -m 0644                 /tmp/buildkite-agent.gitconfig  /var/lib/buildkite-agent/.gitconfig",

      "systemctl enable buildkite-agent.service",

      "mkdir /var/lib/buildkite-agent/.ssh/",
      "install -m 0600 /tmp/buildkite-agent.known_hosts /var/lib/buildkite-agent/.ssh/known_hosts",
      "chown -R buildkite-agent:buildkite-agent /var/lib/buildkite-agent/.ssh/",

      # Install build tools

      "apt-get -y update",
      "apt-get -y install build-essential dpkg-dev sbuild schroot debootstrap git-buildpackage debhelper dh-lua gem2deb",

      "sbuild-adduser buildkite-agent",

      "rm -f /etc/apt/apt.conf.d/proxy.conf",
    ]
  }

  provisioner "shell" {
    script = "build-chroots.pl"
    environment_vars = [
      "http_proxy=${var.http_proxy}",
      "https_proxy=${var.https_proxy}",
    ]
  }

  provisioner "shell" {
    script = "clean-system.sh"
  }

  post-processor "shell-local" {
    keep_input_artifact = true
    inline = [
      "cd ${var.output_dir}/",
      "sha256sum debian-build-agent.qcow2 > SHA256SUMS",
    ]
  }
}

source qemu "debian" {
  iso_url      = "file:${abspath(path.root)}/../../packer-qemu-debian-bookworm/output/latest/qemu-debian-bookworm.qcow2"
  iso_checksum = "file:${abspath(path.root)}/../../packer-qemu-debian-bookworm/output/latest/SHA256SUMS"
  disk_image   = true

  # Create a full copy of the base image
  use_backing_file = false

  cpus        = 4
  memory      = 4096
  disk_size   = 24000
  accelerator = "kvm"

  headless = true
  # vnc_bind_address = "0.0.0.0"

  # SSH ports to redirect to the VM being built
  host_port_min = 2222
  host_port_max = 2229

  ssh_username     = "root"
  ssh_password     = "${var.ssh_password}"
  ssh_wait_timeout = "1000s"

  shutdown_command = "/sbin/shutdown -hP now"

  # Builds a compact image
  disk_discard       = "unmap"
  disk_detect_zeroes = "unmap"
  disk_cache         = "unsafe"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "debian-build-agent.qcow2"
}
