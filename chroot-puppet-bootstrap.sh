#!/bin/bash
# This script starts the post-chroot portion of the arch installation, and is
# kicked off by the arch-install script.

root_dir="$(cd "$(dirname "$0")" && pwd)"

readonly AUR_URL=https://aur.archlinux.org/packages
readonly CONFIG_VARS='CRYPT_DEV PLAIN_PART_NAME BTRFS_ROOT_VOL GRUB_INSTALL_DEV PUPPET_SYSTEM_REPO_URL PUPPET_SYSTEM_REPO DOTFILES_REPO_URL'
readonly HIERA_VARS="${CONFIG_VARS} HOSTNAME WIRED_IFNAME WIRELESS_IFNAME"
readonly INSTALL_VARS="${HIERA_VARS} hiera_yaml hiera_system_yaml puppet_modules puppet_manifests puppet_file"

function die {
  echo "$0 failed with: $1"
  exit 1
}

function test_config {
  for var in "$@"; do
    [[ -n $(eval echo "\$${var}") ]] || die "Error, ${var} variable not defined."
  done
}

function export_vars {
  for var in "$@"; do
    export $var
  done
}

# Load variables from configuration written during inital
# 'arch-install.sh' phase.
function load_config {
  . "${root_dir}/chroot-puppet-bootstrap-config.sh"
  test_config $CONFIG_VARS
  readonly hiera_repo_dir="${PUPPET_SYSTEM_REPO}/hiera"
  readonly hiera_yaml="${hiera_repo_dir}/hiera.yaml"
  readonly hiera_system_yaml="${hiera_repo_dir}/hieradata/system.yaml"
  readonly puppet_modules="${PUPPET_SYSTEM_REPO}/modules"
  readonly puppet_manifests="${PUPPET_SYSTEM_REPO}/manifests"
  readonly puppet_file="${PUPPET_SYSTEM_REPO}/Puppetfile"
}

function set_locale {
  sed -i 's/#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
  echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
  locale-gen
}

function install_boostrap_pkgs {
  pacman --noconfirm -Syu
  pacman --noconfirm -S --needed base-devel
  pacman --noconfirm -S git augeas openssh
}

function make_install_pkg {
  local pkg=$1
  local prefix="$(echo "${pkg}" | cut -c 1,2)"
  sudo -u yaourt bash -c "
    mkdir -p ~/builds
    cd ~/builds
    curl -O "${AUR_URL}/${prefix}/${pkg}/${pkg}.tar.gz"
    tar xf "${pkg}.tar.gz"
    cd "${pkg}"
    makepkg --noconfirm -s
  "
  pushd ~yaourt/builds/"${pkg}"
  pacman --noconfirm -U *.tar.xz
  popd
}

function install_yaourt {
  make_install_pkg package-query
  make_install_pkg yaourt
  cat > /usr/local/bin/yaourt <<EOF
#!/bin/bash
sudo -u yaourt "$@"
EOF
  chmod 755 /usr/local/bin/yaourt
  hash -r
}

function install_puppet {
  yaourt --noconfirm -Sa puppet
  yaourt --noconfirm -Sa ruby-hiera
  gem install --user-install librarian-puppet
}

function set_root_pw {
  echo "Enter password for root user"
  passwd
}

function network_config {
  read -p "Enter hostname for new system (no periods): " HOSTNAME
  echo "Choose wired network interface to configure, see the following output of 'ip link' for reference"
  ip link
  read -p "Enter wired network interface name: " WIRED_IFNAME
  read -p "Enter wireless network interface name: " WIRELESS_IFNAME
}

function configure_hiera {
  test_config $INSTALL_VARS
  export_vars $HIERA_VARS

  mkdir -p /etc/puppet/hieradata
  rm -f /etc/hiera.yaml /etc/puppet/hiera.yaml
  ln -s "${hiera_yaml}" /etc/hiera.yaml
  ln -s /etc/hiera.yaml /etc/puppet/hiera.yaml

  erb "${hiera_system_yaml}.erb" > "${hiera_system_yaml}"
  ln -s "${hiera_system_yaml}" /etc/puppet/hieradata/system.yaml
}

function install_puppet_modules {
  test_config $INSTALL_VARS
  mkdir -p /etc/puppet/modules
  for module in "${puppet_modules}"/*; do
    ln -s "${module}" "/etc/puppet/modules/$(basename "${module}")"
  done
}

function install_3rd_party_puppet_modules {
  ln -s "${puppet_file}" /etc/puppet/Puppetfile
  gem_root="$(find /root/.gem -type d -name bin | grep -v gems | sort -V | tail -1)"
  (cd /etc/puppet && "${gem_root}/librarian-puppet" install) || die "Failed to install puppet modules"
}

function install_site_manifest {
  local site_pp="${puppet_manifests}/site.pp"
  erb "${site_pp}.erb" > "${site_pp}"
  mkdir -p /etc/puppet/manifests
  ln -s "${site_pp}" /etc/puppet/manifests/site.pp
}

function setup_puppet {
  export_vars $INSTALL_VARS
  test_config $INSTALL_VARS
  for module in "${puppet_modules}"/*; do
    module_list="$(basename "${module}") ${module_list}"
  done

  install_3rd_party_puppet_modules
  install_puppet_modules

  export module_list
  install_site_manifest

  chown -R puppet:puppet /etc/puppet /var/lib/puppet "${PUPPET_SYSTEM_REPO}"

  # Fix hostname resolution without fqdn so puppet SSL certs work
  augtool <<EOF
set /files/etc/puppet/puppet.conf/main/server ${HOSTNAME}
set /files/etc/puppet/puppet.conf/main/certname ${HOSTNAME}
rm /files/etc/hosts/*[ipaddr = '127.0.0.1']/alias
set /files/etc/hosts/*[ipaddr = '127.0.0.1']/canonical ${HOSTNAME}
set /files/etc/hosts/*[ipaddr = '127.0.0.1']/alias[. = 'localhost'] localhost
save
EOF
}

function puppet_install_system {
  puppet apply -e 'include util::augeas'
  puppet apply -e 'include t530_arch_system_core'
}

function main {
  load_config
  install_boostrap_pkgs
  git clone "${PUPPET_SYSTEM_REPO_URL}" "${PUPPET_SYSTEM_REPO}" || die "Failed to clone ${PUPPET_SYSTEM_REPO_URL} to ${PUPPET_SYSTEM_REPO}"

  set_locale
  useradd -m yaourt
  install_yaourt
  install_puppet

  # Interactive
  set_root_pw
  network_config

  configure_hiera
  setup_puppet

  puppet_install_system

  systemctl enable puppetmaster
  systemctl enable puppet
}

main


# TODO in users module:
# SUDO
# USER phil
# ADD to sudoers
#salt=$(dd if=/dev/urandom | tr -dc '[:alnum:]' | head -c 16)
## allow members of group 'sudo' to use sudo
#sed -i 's/.*%\(sudo\s\+ALL=(ALL) ALL\)/\1/' /etc/sudoers
# X config

# Reboot
# Run all puppet modules

# TODO:
# wifi

# profile-sync-daemon in aur
# xmonad
