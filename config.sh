# Configuration for arch-install and arch-install-bootstrap

# Specify install partitions as absolute paths to top-level device files, e.g. /dev/sda1
# Note: the install script doesn't work with the links under /dev/disk/*, so one
# must use /dev/sda etc.

# Boot partition. Grub will be installed to this disk, so set the BIOS to boot
# from it
BOOT_PART=/dev/sda1

# Encrypted partition. Will hold encrypted volume for rest of system.
ENC_PART=/dev/sda2

# Puppet module repository git url
PUPPET_MODULE_REPO_URL=phil@192.168.1.115:/home/phil/arch/puppet-arch-modules
# Puppet module repository root absolute path, must contain ./modules
PUPPET_MODULE_REPO=/etc/puppet/modules.git
