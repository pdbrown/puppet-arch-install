class arch_laptop_install::grub ($grub_cmdline_linux, $grub_install_device) {
  package {'os-prober':
    ensure => present,
  }
  ->
  package {'grub':
    ensure => present,
  }
  ->
  augeas {'/etc/default/grub':
    context => '/files/etc/default/grub',
    changes => [
      "set GRUB_CMDLINE_LINUX '\"${grub_cmdline_linux}\"'",
      # Temporary workaround to /etc/grub.d/10_linux bug
      'set GRUB_DISABLE_SUBMENU y',
    ]
  }
  ~>
  exec {'grub-mkconfig':
    subscribe   => Exec['mkinitcpio'],
    command     => '/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg',
    refreshonly => true,
  }
  ~>
  exec {'grub-install':
    command     => "/usr/bin/grub-install ${grub_install_device}",
    refreshonly => true,
  }
}
