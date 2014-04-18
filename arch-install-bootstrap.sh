#!/bin/bash
# This script installs arch linux using puppet. It clones the
# puppet-arch-install repo, renders a config file, and runs the installer.

# Define config.sh
# Configuration for arch-install.sh

# Specify install partitions as absolute paths to top-level device files, e.g. /dev/sda1
# Note: the install script doesn't work with the links under /dev/disk/*

# Boot partition. Grub will be installed to this disk, so set the BIOS to boot
# from it
declare -rx BOOT_PART=/dev/sda1

# Encrypted partition. Will hold encrypted volume for rest of system.
declare -rx ENC_PART=/dev/sda2

# Puppet repo to clone. This repo must contain
#     * puppet/modules
#     * puppet/hieradata
#     * chroot-puppet-bootstrap.sh
readonly PUPPET_REPO_URL=/opt/git/puppet-install
readonly PUPPET_REPO_DEST=/opt/scripts/puppet-install


# Bootstrap install

root_dir=$(cd $(dirname $0) && pwd)

pacman --noconfirm -Sy
pacman --noconfirm -S git

mkdir -p "${PUPPET_REPO_DEST}"
cd "${PUPPET_REPO_DEST}"
git clone "${PUPPET_REPO_URL}"
latest="$(ls -1tr | tail -1)"
cd "${latest}"

bash arch-install.sh
