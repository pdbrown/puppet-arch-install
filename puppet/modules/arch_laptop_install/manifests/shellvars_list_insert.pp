# Insert ${value} into whitespace delimited array ${key}
# in ${file}, at an undefined position.
# Uses the Shellvars_list.lns augeas lens which parses shell
# variables like HOME="/home/user", or ARR="a b c d e"

define arch_laptop_install::shellvars_list_insert ($file, $key, $value) {
  if $file !~ /^\/.*/ {
    fail('${file} must be an absolute path and start with /')
  }
  $lens = "Shellvars_list.lns"
  $context = "/files${file}"

  # Insert ${value} from list ${key}
  augeas {"${file}::${key}::${value}":
    lens    => $lens,
    incl    => $file,
    context => "/files${file}",
    changes => [
      "set ${key}/value[. = '${value}'] ${value}",
    ],
  }
}
