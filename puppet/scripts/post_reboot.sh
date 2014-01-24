#!/bin/bash

function die {
  echo "${0} failed with: ${1}"
  exit 1
}
function test_puppet_detailed_exitcode {
  exitcode="${1}"
  if [ "${exitcode}" -eq 4 ]; then
    die "Puppet encountered failures."
  fi
  if [ "${exitcode}" -eq 6 ]; then
    die "Puppet made changes but also encountered failures."
  fi
}
root_dir=$(cd $(dirname "${0}") && pwd)
tmp_pp_file="${root_dir}/tmp.pp"
trap "rm -rf ${tmp_pp_file}" EXIT

# Bring up ethernet interfaces and start dhcp
for interface in "$(find /sys/class/net -type l | grep en)"; do
  if_name="$(basename "${interface}")"
  ip link set dev "${if_name}" up
  systemctl start "dhcpcd@${if_name}.service"
done

# Apply arch_laptop module
echo "include arch_laptop" > "${tmp_pp_file}"

puppet apply --detailed-exitcodes "${tmp_pp_file}"
test_puppet_detailed_exitcode $?

# Install puppet cron job
#TODO
