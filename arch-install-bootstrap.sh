#!/bin/bash
# This script installs arch linux using puppet. It clones the
# puppet-arch-install repo, renders a config file, and runs the installer.

# Define config.sh
# Configuration for arch-install.sh

# Specify install partitions as absolute paths to top-level device files, e.g. /dev/sda1
# Note: the install script doesn't work with the links under /dev/disk/*

# Boot partition. Grub will be installed to this disk, so set the BIOS to boot
# from it
boot_part="/dev/sda1"

# Encrypted partition. Will hold encrypted volume for rest of system.
enc_part="/dev/sda2"

# Puppet repo to clone. This repo must contain
#     * puppet/modules
#     * puppet/hieradata
#     * chroot-puppet-bootstrap.sh
arch_install_git_url=/opt/repos/puppet-install


# Bootstrap install

root_dir=$(cd $(dirname $0) && pwd)

pacman --noconfirm -Sy
pacman --noconfirm -S git

git clone ${arch_install_git_url}
latest=$(ls -1tr | tail -1)
cd "${latest}"

cat > config.sh <<EOF
boot_part=$boot_part
enc_part=$enc_part
EOF

bash arch-install.sh
