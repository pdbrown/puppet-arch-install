# Configuration for arch-install.sh

# Specify install partitions as absolute paths to top-level device files, e.g. /dev/sda1
# Note: the install script doesn't work with the links under /dev/disk/*

# Boot partition. Grub will be installed to this disk, so set the BIOS to boot
# from it
test "${BOOT_PART}" || readonly BOOT_PART=/dev/sda1

# Encrypted partition. Will hold encrypted volume for rest of system.
test "${ENC_PART}" || readonly ENC_PART=/dev/sda2
