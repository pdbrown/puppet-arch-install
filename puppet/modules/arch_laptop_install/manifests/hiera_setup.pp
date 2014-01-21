class arch_laptop_install::hiera_setup {
  File {
    mode  => 0600,
    owner => root,
    group => root,
  }

  file {'/etc/puppet/hieradata':
    ensure => directory,
    before => File['/etc/puppet/hiera.yaml'],
  }

  file {'/etc/hiera.yaml':
    ensure => file,
    source => 'puppet:///modules/arch_laptop_install/hiera/hiera.yaml',
  }
  ->
  file {'/etc/puppet/hiera.yaml':
    ensure => link,
    target => '/etc/hiera.yaml',
  }
}
