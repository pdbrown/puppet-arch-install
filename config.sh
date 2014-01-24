# Configuration for arch-install.sh

# Specify install partitions as absolute paths to top-level device files, e.g. /dev/sda1
# Note: the install script doesn't work with the links under /dev/disk/*

# Boot partition. Grub will be installed to this disk, so set the BIOS to boot
# from it
boot_part="/dev/sda1"

# Encrypted partition. Will hold encrypted volume for rest of system.
enc_part="/dev/sda2"
