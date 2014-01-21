# Order matters: dump and passno nodes must be inserted after opt values
# passno:
# 0: don't fsck
# 1: fsck first
# 2: fsck after 1

define arch_laptop_install::fstab_ssd_ext4 ($mount_point = $title) {
  augeas {"/etc/fstab::${mount_point}":
    context => '/files/etc/fstab',
    changes => [
      "rm  *[descendant::file = '${mount_point}']/opt",
      "rm  *[descendant::file = '${mount_point}']/dump",
      "rm  *[descendant::file = '${mount_point}']/passno",
      "set *[descendant::file = '${mount_point}']/opt[. = 'discard'] discard",
      "set *[descendant::file = '${mount_point}']/opt[. = 'data'] data",
      "set *[descendant::file = '${mount_point}']/opt[. = 'data']/value writeback",
      "set *[descendant::file = '${mount_point}']/dump 0",
      "set *[descendant::file = '${mount_point}']/passno 2",
    ]
  }
}
