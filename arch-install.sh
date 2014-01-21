#!/bin/bash
# This script installs arch linux using puppet. It:
#   1) Takes two partitions specified in ./config.sh for:
#       * An unencrypted boot partition (needs 300MB +- 200MB)
#       * A btrfs on top of an encrypted partition (needs > 2GB):
#           * '@' subvol:     /
#           * '@home' subvol: /home
#           * '@var' subvol:  /var
#   2) Creates an ext4 fs on the boot partition, and the btrfs as described
#      above.
#   2) Installs base.
#   3) Installs puppet.
#   4) Uses puppet modules to install the rest of the system.
#
# Instructions:
#   1) Boot arch iso on target machine
#   2) Connect it to the internet
#   3) Run the following:
#        # Don't use pacman's built-in downloader because it times out after 10s
#        sed -i 's/#\(XferCommand.*curl.*\)/\1/' /etc/pacman.conf
#        pacman --noconfirm -Sy
#        pacman --noconfirm -S git
#        cd ~
#        git clone git@github.com:pdbrown/puppet-arch-install.git
#        cd puppet-arch-install
#   4) Edit config.sh to configure installation partitions. WARNING: their old
#      contents will be wiped out. Note that you need to create these first (see
#      sample-init-disk.sh)
#   5) run ./arch-install.sh

function die {
  echo "$0 failed with: $1"
  exit 1
}

root_dir=$(cd $(dirname $0) && pwd)
read -p "This script will install arch linux. Do you want to continue (y/N): " install_flag
echo $install_flag
if [ "$install_flag" != y ] && [ "$install_flag" != Y ]; then
  exit 2
fi


###############################################################################
# Disk and filesystem setup
#
# Configures partitions according to $root_dir/config.sh
# Creates ext4 /boot fs on $boot_part
# Encrypts $enc_part
# Mounts $enc_part as $plain_part
# Creates btrfs filesystem and subvolues on $plain_part
# Mounts btrfs on /mnt
###############################################################################

# Load partition config
source "${root_dir}/config.sh"
[ -f $boot_part ] || die "\$boot_part: '${boot_part}' does not exist. See ${root_dir}/config.sh"
[ -f $enc_part  ] || die "\$enc_part: '${enc_part}' does not exist. See ${root_dir}/config.sh"
echo "Arch installer configured with:"
echo "boot_part=${boot_part}"
echo "enc_part=${enc_part}"
echo "WARNING: Continuing the installation will WIPE ALL DATA on partitions above."
read -p "Do you want to continue (y/N): " install_flag
echo $install_flag
if [ "$install_flag" != y ] && [ "$install_flag" != Y ]; then
  exit 2
fi

boot_disk=$(echo ${boot_partition} | tr -d '[0-9]')
boot_disk_name=$(basename ${boot_disk})
boot_part_num=$(basename ${boot_partition} | tr -d '[a-z]')

plain_name="$(basename ${enc_part})_crypt"
plain_part="/dev/mapper/${enc_part_name}"

# Create unencrypted /boot fs
mkfs.ext4 ${boot_part}

# Encrypt root device
cryptsetup --use-random luksFormat ${enc_part}
cryptsetup open ${enc_part} ${plain_name}

# Create btrfs tank on plaintext partition, prepare subvolumes
mkfs.btrfs -L tank ${plain_part}
mount ${plain_part} /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@home

# Mount partitions
mount ${plain_part} -o subvol=@ /mnt
mkdir /mnt/var /mnt/home /mnt/boot

mount ${plain_part} -o subvol=@var /mnt/var
mount ${plain_part} -o subvol=@home /mnt/home


###############################################################################
# Base system install
###############################################################################

sed -i 's/#\(XferCommand.*curl.*\)/\1/' /etc/pacman.conf
pacstrap -i /mnt base

# Generate fstab
genfstab -p -U /mnt >> /mnt/etc/fstab


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

arch-chroot /mnt /bin/bash

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
makepkg -s
cd ..
cd yaourt
makepkg -s
cd ..
yaourt puppet


###############################################################################
# Full system configuration with puppet
#
# Examine puppet-arch-install/puppet for details
###############################################################################


#TODO render hieradata template
#enc_part_uuid=$(ls -l /dev/disk/by-uuid/ | grep ${root_part} | awk '{print $(NF-2)}')
#sed -i 's|\(GRUB_CMDLINE_LINUX\)=.*|\1="cryptdevice=/dev/disk/by-uuid/'${enc_part_uuid}':cryptroot"| /etc/default/grub'
#hostname
#TODO Run chroot_setup.sh


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
