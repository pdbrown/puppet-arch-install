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

# update system, verify git
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
yaourt --noconfirm -Sa ruby-hiera

###############################################################################
# Full system configuration with puppet
#
# Examine puppet-arch-install/puppet for details
###############################################################################

echo "Enter password for root user"
passwd

# Load variables from configuration written during inital
# 'arch-install.sh' phase.
. ${root_dir}/chroot-puppet-bootstrap-config.sh
[ -n "$CRYPT_DEV" ] || die "Error, CRYPT_DEV variable not defined."
[ -n "$PLAIN_PART_NAME" ] || die "Error, PLAIN_PART_NAME variable not defined."
[ -n "$BTRFS_ROOT_VOL" ] || die "Error, BTRFS_ROOT_VOL variable not defined."
[ -n "$GRUB_INSTALL_DEV" ] || die "Error, GRUB_INSTALL_DEV variable not defined."

# Read values for system configuration
read -p "Enter hostname for new system: " HOSTNAME
echo "Choose wired network interface to configure, see the following output of 'ip link' for reference"
ip link
read -p "Enter wired network interface name: " WIRED_IFNAME

# Export configuratin for hieradata/system.yaml
export CRYPT_DEV PLAIN_PART_NAME BTRFS_ROOT_VOL GRUB_INSTALL_DEV HOSTNAME WIRED_IFNAME

# Render hieradata template
hiera_system="${root_dir}/hiera/hieradata/system.yaml"
erb "${hiera_system}.erb" > "${hiera_system}"

# Install symlinks to puppet modules and hiera data
mkdir -p /etc/puppet/modules /etc/puppet/hieradata
rm -f /etc/hiera.yaml
ln -s ${root_dir}/hiera/hiera.yaml /etc/hiera.yaml
ln -s /etc/hiera.yaml /etc/puppet/hiera.yaml
ln -s ${root_dir}/hiera/hieradata/system.yaml /etc/puppet/hieradata/system.yaml
for module in ${root_dir}/puppet/modules/*; do
  ln -s ${module} /etc/puppet/modules/$(basename $module)
done

# Run install modules
puppet apply <(echo include arch_laptop_install::augeas)
puppet apply <(echo include arch_laptop_install)

# Finish puppet setup
augtool <<EOF
set /files/etc/puppet/puppet.conf/main/server $HOSTNAME
save
EOF

site_pp=${root_dir}/puppet/site.pp
erb "${site_pp}.erb" > "${site_pp}"
mkdir -p /etc/puppet/manifests
ln -s "${site_pp}" /etc/puppet/manifests/site.pp

chgrp -R puppet ${root_dir}

systemctl enable puppetmaster
systemctl enable puppet


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
# sysctl, harden kernel
# sysctl, deadline scheduler
# firewall

# profile-sync-daemon in aur
# X
# xmonad
