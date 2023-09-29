# debian-build-agent

This repository contains scripts for building and deploying Buildkite agent VMs with all the software needed to build packages for Debian/Ubuntu.

The configuration files are for my personal deployment, and you will need to tweak them (e.g. changing the `meta-data` in `buildkite-agent.cfg` and the hypervisors in `main.tf`) to make use of it yourself.

[packer-qemu-debian-bookworm](https://github.com/solemnwarning/packer-qemu-debian-bookworm) is used as a base and should be checked out and built in the directory alongside this repository first.

Once the `packer-qemu-debian-bookworm` image is built, `build.sh` can be used to build a QEMU/KVM virtual machine image which will include the Buildkite agent, Debian/Ubuntu chroots, git-buildpackage, sbuild and other tools necessary for building packages.

Finally, `deploy.sh` is used to actually deploy it to some libvirt hypervisors along with a cloud-init disk which will perform configuration such as setting up a HTTP proxy (if used), setting a unique hostname on each instance, setting the root password and injecting secrets including the Buildkite agent token and SSH host keys.
