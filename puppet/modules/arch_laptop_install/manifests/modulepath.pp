class arch_laptop_install::modulepath {
  augeas {'/etc/puppet/puppet.conf':
    context => "/files/etc/puppet/puppet.conf",
    changes => [
      "set main/modulepath /etc/puppet/modules:/root/puppet/modules",
    ]
  }
}
