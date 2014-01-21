# Set ${value} before value ${pos} in whitespace delimited array ${key}
# in ${file}. Ensures ${value} occurs nowhere else. Uses the
# Shellvars_list.lns augeas lens which parses shell variables like
# HOME="/home/user", or ARR="a b c d e"

define arch_laptop_install::shellvars_list_insert_before ($file, $key, $value, $pos) {
  if $file !~ /^\/.*/ {
    fail('${file} must be an absolute path and start with /')
  }
  $lens = "Shellvars_list.lns"
  $context = "/files${file}"

  # Insert ${value} into list ${key} before ${pos}
  augeas {"${file}::${key}::${value}":
    lens    => $lens,
    incl    => $file,
    context => $context,
    onlyif  => "match ${key}/value[. = '${value}'] size == 0",
    changes => [
      "ins value before ${key}/value[. = '${pos}']",
      "set ${key}/value[following-sibling::*[1] = '${pos}'] ${value}",
    ]
  }
  # Remove ${value} and reinsert if in wrong position
  augeas {"${file}::${key}::${value}::clean":
    notify  => Augeas["${file}::${key}::${value}"],
    lens    => $lens,
    incl    => $file,
    context => $context,
    onlyif  => "match ${key}/value[following-sibling::*[1] != '${pos}'][. = '${value}'] size > 0",
    changes => [
      "rm ${key}/value[. = '${value}']",
    ],
  }
}
