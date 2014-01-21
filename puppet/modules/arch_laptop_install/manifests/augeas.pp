class arch_laptop_install::augeas {
  package {'augeas':
    ensure => present,
  }
  package {'ruby-augeas':
    ensure  => present,
    require => Package['augeas'],
  }
  Package['ruby-augeas'] -> Augeas <| |>
}
