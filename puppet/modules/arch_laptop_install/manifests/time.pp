class arch_laptop_install::time {

  $time_zone = 'America/Los_Angeles'

  file {'/etc/localtime':
    ensure => link,
    target => "/usr/share/zoneinfo/$time_zone"
  }
  exec {'hwclock':
    refreshonly => true,
    command     => '/usr/bin/hwclock --systohc --utc',
    subscribe   => File['/etc/localtime']
  }
  #TODO: chrony + hooks into ifupdown
}
