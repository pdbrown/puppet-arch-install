# Configures /etc/mkinitcpio.conf. Doesn't guard agains misspellings.
# Insert encrypt hook before filesystems hook
class arch_laptop_install::mkinitcpio_conf {
  # Enable crypt devices before filesystems start
  shellvars_list_insert_before {'mkinitcpio.conf::HOOKS::encrypt':
    file  => '/etc/mkinitcpio.conf',
    key   => 'HOOKS',
    value => 'encrypt',
    pos   => 'filesystems'
  }
  # Add shutdown hook to end, so crypt devices/btrfs are unmounted
  shellvars_list_append {'mkinitcpio.conf::HOOKS::shutdown':
    file  => '/etc/mkinitcpio.conf',
    key   => 'HOOKS',
    value => 'shutdown',
  }
  # Remove fsck hook, as neither / or /usr need fsck
  shellvars_list_remove {'mkinitcpio.conf::HOOKS::fsck':
    file  => '/etc/mkinitcpio.conf',
    key   => 'HOOKS',
    value => 'fsck',
  }
  # Configure modules
  shellvars_list_insert {'mkinitcpio.conf::HOOKS::crc32c-intel':
    file  => '/etc/mkinitcpio.conf',
    key   => 'MODULES',
    value => 'crc32c-intel',
  }
  exec {'mkinitcpio':
    refreshonly => true,
    command     => '/usr/bin/mkinitcpio -p linux',
    subscribe   => [
      Augeas['/etc/mkinitcpio.conf::HOOKS::encrypt'],
      Augeas['/etc/mkinitcpio.conf::HOOKS::shutdown'],
      Augeas['/etc/mkinitcpio.conf::HOOKS::fsck'],
      Augeas['/etc/mkinitcpio.conf::MODULES::crc32c-intel'],
    ]
  }
}
