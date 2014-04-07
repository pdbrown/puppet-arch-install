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
[ -b "${boot_part}" ] || die "\$boot_part: '${boot_part}' does not exist. See ${root_dir}/config.sh"
[ -b "${enc_part}"  ] || die "\$enc_part: '${enc_part}' does not exist. See ${root_dir}/config.sh"
[ -z "${puppet_repo_url}"  ] || die "\$puppet_repo_url: '${puppet_repo_url}' is not defined. See ${root_dir}/config.sh"
echo "Arch installer configured with:"
echo "boot_part=${boot_part}"
echo "enc_part=${enc_part}"
echo "arch_install_git_url=${arch_install_git_url}"
echo "WARNING: Continuing the installation will WIPE ALL DATA on partitions above."
read -p "Do you want to continue (y/N): " install_flag
echo $install_flag
if [ "$install_flag" != y ] && [ "$install_flag" != Y ]; then
  exit 2
fi

boot_disk=$(echo ${boot_part} | tr -d '[0-9]')
boot_disk_name=$(basename ${boot_disk})
boot_part_num=$(basename ${boot_part} | tr -d '[a-z]')

enc_part_name=$(basename ${enc_part})

plain_part_name="${enc_part_name}_crypt"
plain_part="/dev/mapper/${plain_part_name}"

btrfs_root_vol=@

# Create unencrypted /boot fs
mkfs.ext4 ${boot_part}

# Encrypt root device
cryptsetup --use-random luksFormat ${enc_part}
cryptsetup open ${enc_part} ${plain_part_name}

# Create btrfs tank on plaintext partition, prepare subvolumes
mkfs.btrfs -L tank ${plain_part}
mount ${plain_part} /mnt
btrfs subvolume create /mnt/${btrfs_root_vol}
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@home
umount /mnt

# Mount partitions
mount ${plain_part} -o subvol=${btrfs_root_vol} /mnt
mkdir /mnt/var /mnt/home /mnt/boot

mount ${plain_part} -o subvol=@var /mnt/var
mount ${plain_part} -o subvol=@home /mnt/home
mount ${boot_part} /mnt/boot


###############################################################################
# Base system install
###############################################################################

sed -i 's/#\(XferCommand.*curl.*\)/\1/' /etc/pacman.conf
pacstrap /mnt base

# Generate fstab
genfstab -p -U /mnt >> /mnt/etc/fstab


###############################################################################
# System setup prep
###############################################################################

# update system, get git
pacman --noconfirm -Syu
pacman --noconfirm -S --needed base-devel
pacman --noconfirm -S git

# Get install scripts
mkdir -p /mnt/opt/system && cd /mnt/opt/system
git clone ${arch_install_git_url}
latest=$(ls -1tr | tail -1)
cd "${latest}"
repo_dir="$(cd $(dirname $0) && pwd)"

# Configure setup scripts
bootstrap_config=${repo_dir}/chroot-puppet-bootstrap-config.sh
crypt_dev_uuid=$(lsblk -o NAME,UUID | grep ${enc_part_name} | grep -v ${plain_part_name} | awk '{print $2}')
cat > ${bootstrap_config} <<EOF
CRYPT_DEV=/dev/disk/by-uuid/${crypt_dev_uuid}
PLAIN_PART_NAME=${plain_part_name}
BTRFS_ROOT_VOL=${btrfs_root_vol}
GRUB_INSTALL_DEV=${boot_disk}
EOF

chroot_repo_dir=$(echo $repo_dir | sed 's/^\/mnt//')
chmod u+x ${chroot_repo_dir}/chroot-puppet-bootstrap.sh
arch-chroot /mnt /bin/bash -c ${chroot_repo_dir}/chroot-puppet-bootstrap.sh && reboot
