class arch_laptop::network_wired ($wired_interface) {
  service {"dhcpcd@${wired_interface}.service":
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/dhcpcd.conf'],
  }
}
