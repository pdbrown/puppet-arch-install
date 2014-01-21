class arch_laptop_install::hostname ($hostname) {
  file {'/etc/hostname':
    ensure => present,
    content => $hostname,
  }
}
