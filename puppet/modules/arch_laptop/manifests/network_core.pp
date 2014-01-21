class arch_laptop::network_core {
  package {'openresolv':
    ensure => present,
    before => File['/etc/resolvconf.conf'],
  }
  file {'/etc/resolvconf.conf':
    ensure  => file,
    source  => "puppet:///modules/arch_laptop/network/resolvconf.conf",
  }

  package {'dnsmasq':
    ensure => present,
    before => File['/etc/dnsmasq.conf'],
  }
  file {'/etc/dnsmasq.conf':
    ensure  => file,
    source  => "puppet:///modules/arch_laptop/network/dnsmasq.conf",
  }
  service {'dnsmasq':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/dnsmasq.conf'],
  }

  package {'dhcpcd':
    ensure => present,
    before => File['/etc/dhcpcd.conf'],
  }
  file {'/etc/dhcpcd.conf':
    ensure  => file,
    source  => "puppet:///modules/arch_laptop/network/dhcpcd.conf",
  }

  package {'openssh':
    ensure => present,
    before => File['/etc/ssh/sshd_config'],
  }
  file {'/etc/ssh/sshd_config':
    ensure  => file,
    source  => "puppet:///modules/arch_laptop/network/sshd_config",
  }
}