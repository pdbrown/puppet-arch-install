# Append ${value} to whitespace delimited array ${key}
# in ${file}. Ensures ${value} occurs nowhere else.
# Uses the Shellvars_list.lns augeas lens which parses shell
# variables like HOME="/home/user", or ARR="a b c d e"

define arch_laptop_install::shellvars_list_append ($file, $key, $value) {
  if $file !~ /^\/.*/ {
    fail('${file} must be an absolute path and start with /')
  }
  $lens = "Shellvars_list.lns"
  $context = "/files${file}"

  # Append ${value} into list ${key}
  augeas {"${file}::${key}::${value}":
    lens    => $lens,
    incl    => $file,
    context => "/files${file}",
    onlyif  => "match ${key}/value[last()][. = '${value}'] size == 0",
    changes => [
      "set ${key}/value[last()+1] ${value}",
    ],
  }
  # Remove ${value} and reinsert if not found at end
  augeas {"${file}::${key}::${value}::clean":
    notify => Augeas["${file}::${key}::${value}"],
    lens    => $lens,
    incl    => $file,
    context => "/files/${file}",
    onlyif  => "match ${key}/value[position() < last()][. = '${value}'] size > 0",
    changes => [
      "rm ${key}/value[. = '${value}']",
    ],
  }
}
