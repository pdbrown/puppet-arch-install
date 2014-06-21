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
PUPPET_SYSTEM_REPO_URL=phil@192.168.1.115:/home/phil/arch/puppet-arch-system
# Puppet module repository root absolute path
PUPPET_SYSTEM_REPO=/etc/puppet/system.git

# Dotfiles for primary non-root user
DOTFILES_REPO_URL=github.com:pdbrown/dotfiles.git
