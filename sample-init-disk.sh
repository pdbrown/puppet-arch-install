#!/bin/bash
# Warning this script will destroy old data on /dev/sda
# Creates a new partition table on /dev/sda
# Creates 2 partitions /dev/sda1, and /dev/sda2
# Where /dev/sda1 is 500MB and /dev/sda2 is the remainder of the disk.

disk_name=sda

echo "WARNING: This script will destroy ALL DATA on /dev/${disk_name}"
read -p "Do you want to continue (y/N): " install_flag
echo $install_flag
if [ "$install_flag" != y ] && [ "$install_flag" != Y ]; then
  exit 2
fi

parted -s "/dev/${disk_name}" mktable msdos
sector_size=$(cat "/sys/block/${disk_name}/queue/physical_block_size")
# Max is size in sectors * $sector_size bytes per sector to megabytes minus 1
# (zero based addressing)
max=$(( $(cat "/sys/block/${disk_name}/size") * $sector_size / 1024 / 1024 - 1 ))
# Parted default unit is MB, start at 1 for proper SSD alignment
parted -s /dev/sda/ mkpart primary 1 500
parted -s /dev/sda/ mkpart primary 500 $max
