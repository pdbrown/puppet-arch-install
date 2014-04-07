class arch_laptop_install {
  include augeas
  include fstab
  include grub
  include hostname
  include mkinitcpio_conf
  include time
  include utils
  include network_core
}
