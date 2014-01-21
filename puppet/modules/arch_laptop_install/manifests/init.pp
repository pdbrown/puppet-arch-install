class arch_laptop_install {
  stage {'first':
    before => Stage['main'],
  }
  class {'modulepath':
    stage => first
  }
  class {'augeas':
    stage => first
  }
  class {'hiera_setup':
    stage => first
  }

  include fstab
  include grub
  include hostname
  include mkinitcpio_conf
  include time
  include utils
}
