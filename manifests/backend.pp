class aegir::backend (
  $api      = $aegir::defaults::api,
  $dist     = $aegir::defaults::dist,
  $ensure   = $aegir::defaults::ensure
  ) inherits aegir::defaults {

  class { 'drush': }

  if $dist {
    class { 'aegir::apt' :
      dist   => $dist,
      before => Package["aegir-provision${real_api}"]
    }
  }

  case $api {
    2: {
      $real_api = 2
      package { 'aegir-provision':
        ensure => absent;
      }
    }
    1, '': {
      $real_api = ''
    }
    default: {
      warning("'${api}' is not a valid Aegir API version. Values can be '1' or '2'. Defaulting to '1'.")
      $real_api = ''
    }
  }

  package { "aegir-provision${real_api}" :
    ensure  => $ensure,
    require => Class['drush'],
  }
}
