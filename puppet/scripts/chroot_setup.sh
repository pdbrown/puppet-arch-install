#!/bin/bash
root_dir=$(cd $(dirname "$0") && pwd)
module_path="${root_dir}/../modules"
hieradata_path="${root_dir}/../hieradata"
module=arch_laptop_install
tmp_pp_dir="${root_dir}/init_pp"

function die {
  echo "$0 failed with: $1"
  exit 1
}
function test_puppet_detailed_exitcode {
  exitcode=$1
  if [ $exitcode -eq 4 ]; then
    die "Puppet encountered failures."
  fi
  if [ $exitcode -eq 6 ]; then
    die "Puppet made changes but also encountered failures."
  fi
}

trap "rm -rf ${tmp_pp_dir}" EXIT

# Initialize tmp_pp_dir and pp files
mkdir -p "${tmp_pp_dir}" || die "Error creating ${tmp_pp_dir}"

cp "${module_path}/${module}/manifests/augeas.pp" "${tmp_pp_dir}" || die "Error copying augeas module"
cp "${module_path}/${module}/manifests/modulepath.pp" "${tmp_pp_dir}" || die "Error copying modulepath module"

echo "include ${module}::augeas" >> "${tmp_pp_dir}/augeas.pp" || die "Error editing augeas module"
echo "include ${module}::modulepath" >> "${tmp_pp_dir}/modulepath.pp" || die "Error editing modulepath module"
echo "include ${module}::hiera_setup" >> "${tmp_pp_dir}/hiera_setup.pp" || die "Error creating hiera_setup include"
echo "include ${module}" >> "${tmp_pp_dir}/arch_laptop_install.pp" || die "Error creating arch_laptop_install include"

# Apply augeas and modulepath
puppet apply --detailed-exitcodes "${tmp_pp_dir}/augeas.pp"
test_puppet_detailed_exitcode $?
puppet apply --detailed-exitcodes "${tmp_pp_dir}/modulepath.pp"
test_puppet_detailed_exitcode $?

# Apply hiera_setup 
puppet apply --detailed-exitcodes "${tmp_pp_dir}/hiera_setup.pp"
test_puppet_detailed_exitcode $?
cp -r "${hieradata_path}"/* /etc/puppet/hieradata

# Bootstrap rest of system
puppet apply --detailed-exitcodes "${tmp_pp_dir}/arch_laptop_install.pp"
test_puppet_detailed_exitcode $?
