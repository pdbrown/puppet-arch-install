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
  echo "${0} failed with: ${1}"
  exit 1
}

readonly root_dir="$(cd "$(dirname "${0}")" && pwd)"
read -p "This script will install arch linux. Do you want to continue (y/N): " install_flag
echo "${install_flag}"
if ! [[ "${install_flag}" =~ [yY] ]]; then
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
[ -b "${BOOT_PART}" ] || die "\$boot_part: '${BOOT_PART}' does not exist. See ${root_dir}/config.sh"
[ -b "${ENC_PART}" ] || die "\$enc_part: '${ENC_PART}' does not exist. See ${root_dir}/config.sh"
echo "Arch installer configured with:"
echo "BOOT_PART=${BOOT_PART}"
echo "ENC_PART=${ENC_PART}"
echo "WARNING: Continuing the installation will WIPE ALL DATA on partitions above."
read -p "Do you want to continue (y/N): " install_flag
echo $install_flag
if ! [[ "${install_flag}" =~ [yY] ]]; then
  exit 2
fi

readonly boot_disk="$(echo ${BOOT_PART} | tr -d '[0-9]')"
readonly boot_disk_name="$(basename ${boot_disk})"
readonly boot_part_num="$(basename ${BOOT_PART} | tr -d '[a-z]')"
readonly enc_part_name="$(basename ${ENC_PART})"
readonly plain_part_name="${enc_part_name}_crypt"
readonly plain_part="/dev/mapper/${plain_part_name}"

readonly btrfs_root_vol=@

# Create unencrypted /boot fs
mkfs.ext4 "${BOOT_PART}"

# Encrypt root device
cryptsetup --use-random luksFormat "${ENC_PART}"
cryptsetup open "${ENC_PART}" "${plain_part_name}"

# Create btrfs tank on plaintext partition, prepare subvolumes
mkfs.btrfs -L tank "${plain_part}"
mount "${plain_part}" /mnt
btrfs subvolume create "/mnt/${btrfs_root_vol}"
btrfs subvolume create "/mnt/@var"
btrfs subvolume create "/mnt/@home"
umount /mnt

# Mount partitions
mount "${plain_part}" -o subvol="${btrfs_root_vol}" /mnt
mkdir -p /mnt/var /mnt/home /mnt/boot

mount "${plain_part}" -o subvol=@var /mnt/var
mount "${plain_part}" -o subvol=@home /mnt/home
mount "${BOOT_PART}" /mnt/boot


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

# Configure setup scripts
readonly bootstrap_config="${root_dir}/chroot-puppet-bootstrap-config.sh"
readonly crypt_dev_uuid="$(lsblk -o NAME,UUID | grep "${enc_part_name}" | grep -v "${plain_part_name}" | awk '{print $2}')"
cat > "${bootstrap_config}" <<EOF
readonly CRYPT_DEV="/dev/disk/by-uuid/${crypt_dev_uuid}"
readonly PLAIN_PART_NAME="${plain_part_name}"
readonly BTRFS_ROOT_VOL="${btrfs_root_vol}"
readonly GRUB_INSTALL_DEV="${boot_disk}"
EOF

readonly chroot_root_dir="/mnt${root_dir}"
mkdir -p "$(dirname "${chroot_root_dir}")"
cp -r "${root_dir}" "${chroot_root_dir}"
chmod u+x "${chroot_root_dir}/chroot-puppet-bootstrap.sh"
arch-chroot /mnt /bin/bash -c "${root_dir}/chroot-puppet-bootstrap.sh" && reboot
