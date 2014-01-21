class arch_laptop_install::utils {
  package {'mlocate':
    ensure => present,
  }
  ~>
  exec {'updatedb':
    refreshonly => true,
    command     => '/usr/bin/updatedb',
  }

  package {'pkgfile':
    ensure => present,
  }
  ~>
  exec {'pkgfile_update':
    refreshonly => true,
    command     => '/usr/bin/pkgfile --update',
  }

  package { ['lsof',
             'nfs-utils',
             'vim']:
    ensure => present
  }
}
