#!/bin/bash
# This script starts the post-chroot portion of the arch installation, and is
# kicked off by the arch-install script.

root_dir="$(cd "$(dirname "${0}")" && pwd)"

function die {
  echo "$0 failed with: $1"
  exit 1
}

# Load variables from configuration written during inital
# 'arch-install.sh' phase.
. "${root_dir}/chroot-puppet-bootstrap-config.sh"
[ -n "$CRYPT_DEV" ] || die "Error, CRYPT_DEV variable not defined."
[ -n "$PLAIN_PART_NAME" ] || die "Error, PLAIN_PART_NAME variable not defined."
[ -n "$BTRFS_ROOT_VOL" ] || die "Error, BTRFS_ROOT_VOL variable not defined."
[ -n "$GRUB_INSTALL_DEV" ] || die "Error, GRUB_INSTALL_DEV variable not defined."
[ -n "$PUPPET_MODULE_REPO_URL" ] || die "Error, PUPPET_MODULE_REPO_URL variable not defined."
[ -n "$PUPPET_MODULE_REPO" ] || die "Error, PUPPET_MODULE_REPO variable not defined."

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

# Set locale
sed -i 's/#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
locale-gen

# update system, verify git
pacman --noconfirm -Syu
pacman --noconfirm -S --needed base-devel
pacman --noconfirm -S git augeas openssh

# get puppet modules
git clone "${PUPPET_MODULE_REPO_URL}" "${PUPPET_MODULE_REPO}" || die "Failed to clone ${PUPPET_MODULE_REPO_URL} to ${PUPPET_MODULE_REPO}"

# get package-query, yaourt, puppet
readonly aur_url=https://aur.archlinux.org/packages
function make_install_pkg {
  local pkg=$1
  local prefix="$(echo "${pkg}" | cut -c 1,2)"
  mkdir -p ~/builds
  cd ~/builds
  curl -O "${aur_url}/${prefix}/${pkg}/${pkg}.tar.gz"
  tar xf "${pkg}.tar.gz"
  pushd "${pkg}"
  makepkg --asroot --noconfirm -s
  pacman --noconfirm -U *.tar.xz
  popd
}
make_install_pkg package-query
make_install_pkg yaourt

yaourt --noconfirm -Sa puppet
yaourt --noconfirm -Sa ruby-hiera

###############################################################################
# Full system configuration with puppet
#
# Examine puppet-arch-install/puppet for details
###############################################################################

echo "Enter password for root user"
passwd

# Read values for system configuration
read -p "Enter hostname for new system (no periods): " HOSTNAME
echo "Choose wired network interface to configure, see the following output of 'ip link' for reference"
ip link
read -p "Enter wired network interface name: " WIRED_IFNAME

# Export configuratin for hieradata/system.yaml
export CRYPT_DEV PLAIN_PART_NAME BTRFS_ROOT_VOL GRUB_INSTALL_DEV HOSTNAME WIRED_IFNAME

# Render hieradata template
readonly hiera_system="${root_dir}/hiera/hieradata/system.yaml"
erb "${hiera_system}.erb" > "${hiera_system}"

# Install symlinks to puppet modules and hiera data
mkdir -p /etc/puppet/modules /etc/puppet/hieradata
rm -f /etc/hiera.yaml
ln -s "${root_dir}/hiera/hiera.yaml" /etc/hiera.yaml
ln -s /etc/hiera.yaml /etc/puppet/hiera.yaml
ln -s "${root_dir}/hiera/hieradata/system.yaml" /etc/puppet/hieradata/system.yaml
for module in "${PUPPET_MODULE_REPO}"/modules/*; do
  module_name="$(basename "${module}")"
  module_list="${module_name} ${module_list}"
  ln -s "${module}" "/etc/puppet/modules/${module_name}"
done

readonly site_pp="${root_dir}/puppet/site.pp"
export module_list
erb "${site_pp}.erb" > "${site_pp}"
mkdir -p /etc/puppet/manifests
ln -s "${site_pp}" /etc/puppet/manifests/site.pp

chown -R puppet "${root_dir}" "${PUPPET_MODULE_REPO}"

# Fix hostname resolution without fqdn so puppet SSL certs work
augtool <<EOF
set /files/etc/puppet/puppet.conf/main/server ${HOSTNAME}
set /files/etc/puppet/puppet.conf/main/certname ${HOSTNAME}
set /files/etc/hosts/*[ipaddr = '127.0.0.1']/alias[. = '${HOSTNAME}'] ${HOSTNAME}
save
EOF

# Run install modules
puppet apply -e 'include util::augeas'
puppet apply -e 'include t530_arch_system_core'


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
