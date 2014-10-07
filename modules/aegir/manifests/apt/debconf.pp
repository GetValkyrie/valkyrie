define aegir::apt::debconf ( $unless = undef ) {

  if $unless { $real_unless = $unless }
  else {
    $parts = split($name, "[\s]")
    $real_unless = "debconf-get-selections | grep ^debconf | grep ${parts[0]} | grep ${parts[-1]}"
  }

  exec { $name :
    command => "echo debconf ${name} | debconf-set-selections",
    path    => ['/bin', '/usr/bin' ],
    unless  => $real_unless,
  }
}
