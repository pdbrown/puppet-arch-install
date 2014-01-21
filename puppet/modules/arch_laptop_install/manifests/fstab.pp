# Order matters: dump and passno nodes must be inserted after opt values

# fstab notes
# ext4 options: noatime,discard,data=writeback
# btrfs:  ssd,discard,autodefrag,check_int_data,subvol=@ 0 0
    #In /etc/fstab, the mount option subvol="subvolume-name" has to be specified, and the fsck setting in the last field has to be 0.
    #In the kernel boot parameters, use: rootflags=subvol=subvolume-name. It is still necessary to add the standard root parameter with root=/dev/sda1.
    #It is advisable to add crc32c (or crc32c-intel for Intel machines) to the modules array in /etc/mkinitcpio.conf

class arch_laptop_install::fstab {
  fstab_ssd_btrfs {'/':
    subvol      => '@',
  }
  fstab_ssd_btrfs {'home':
    subvol      => '@home',
  }
  fstab_ssd_btrfs {'var':
    subvol      => '@var',
  }
  fstab_ssd_ext4 {'/boot':}
}
