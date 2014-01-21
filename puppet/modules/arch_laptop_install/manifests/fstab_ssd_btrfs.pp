# Order matters: dump and passno nodes must be inserted after opt values

define arch_laptop_install::fstab_ssd_btrfs ($mount_point = $title, $subvol) {
  augeas {"/etc/fstab::${mount_point}":
    context => '/files/etc/fstab',
    changes => [
      "rm  *[descendant::file = '${mount_point}']/opt",
      "rm  *[descendant::file = '${mount_point}']/dump",
      "rm  *[descendant::file = '${mount_point}']/passno",
      "set *[descendant::file = '${mount_point}']/opt[. = 'autodefrag'] autodefrag",
      "set *[descendant::file = '${mount_point}']/opt[. = 'compress'] compress",
      "set *[descendant::file = '${mount_point}']/opt[. = 'discard'] discard",
      "set *[descendant::file = '${mount_point}']/opt[. = 'space_cache'] space_cache",
      "set *[descendant::file = '${mount_point}']/opt[. = 'ssd'] ssd",
      "set *[descendant::file = '${mount_point}']/opt[. = 'subvol'] subvol",
      "set *[descendant::file = '${mount_point}']/opt[. = 'subvol']/value ${subvol}",
      "set *[descendant::file = '${mount_point}']/dump 0",
      "set *[descendant::file = '${mount_point}']/passno 0",
    ]
  }
}
