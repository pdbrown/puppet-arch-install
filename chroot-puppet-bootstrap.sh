#!/bin/bash
# This script starts the post-chroot portion of the installation
# It is sourced by the arch-install.sh script

root_dir=$(cd $(dirname $0) && pwd)

function die {
  echo "$0 failed with: $1"
  exit 1
}

###############################################################################
# System setup
#
# Installs:
#   * base-devel
#   * git
#   * package-query
#   * yaourt
#   * puppet
###############################################################################

echo "Enter password for root user"
passwd

# update system, get git
pacman --noconfirm -Syu
pacman --noconfirm -S --needed base-devel
pacman --noconfirm -S git

# get package-query, yaourt, puppet
mkdir ~/builds
cd ~/builds
curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar xf package-query.tar.gz
tar xf yaourt.tar.gz
cd package-query
makepkg --asroot --noconfirm -s
pacman --noconfirm -U *.tar.xz
cd ..
cd yaourt
makepkg --asroot --noconfirm -s
pacman --noconfirm -U *.tar.xz
cd ..

yaourt --noconfirm -Sa puppet


###############################################################################
# Full system configuration with puppet
#
# Examine puppet-arch-install/puppet for details
###############################################################################

# Read values for system configuration
read -p "Enter hostname for new system: " hostname
echo "Choose wired network interface to configure, see the following output of 'ip link' for reference"
ip link
read -p "Enter wired network interface name: " wired_ifname

# Export system config values for hieradata template
export HOSTNAME=${hostname}
export WIRED_IF=${wired_ifname}

# Export templated variables
# Note that enc_part_name is templated by arch-install.sh before this script is
# run.
crypt_dev=
[ -n "$crypt_dev" ] || die "Error, crypt_dev variable not templated."
plain_part_name=
[ -n "$plain_part_name" ] || die "Error, plain_part_name variable not templated."
btrfs_root_vol=
[ -n "$btrfs_root_vol" ] || die "Error, btrfs_root_vol variable not templated."
grub_install_dev=
[ -n "$grub_install_dev" ] || die "Error, grub_install_dev variable not templated."

export CRYPT_DEV=${crypt_dev}
export PLAIN_PART_NAME=${plain_part_name}
export BTRFS_ROOT_VOL=${btrfs_root_vol}
export GRUB_INSTALL_DEV=${grub_install_dev}

# Render hieradata template
hiera_system="${root_dir}/puppet/hieradata/system.yaml"
erb "${hiera_system}.erb" > "${hiera_system}"

# Run chroot puppet setup
"${root_dir}/puppet/scripts/chroot_setup.sh"


# TODO in arch_laptop_install module:
# SUDO
# USER phil
# ADD to sudoers
#salt=$(dd if=/dev/urandom | tr -dc '[:alnum:]' | head -c 16)
## allow members of group 'sudo' to use sudo
#sed -i 's/.*%\(sudo\s\+ALL=(ALL) ALL\)/\1/' /etc/sudoers

# Reboot
# Run all puppet modules

# TODO:
# wifi
# template grub config cryptdevice
# template grub install device
# sysctl, harden kernel
# sysctl, deadline scheduler
# firewall

# profile-sync-daemon in aur
# X
# xmonad
