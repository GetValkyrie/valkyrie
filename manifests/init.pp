class drush (
  $api    = $drush::defaults::api,
  $dist   = $drush::defaults::dist,
  $ensure = $drush::defaults::ensure
  ) inherits drush::defaults {

  include drush::defaults

  package { 'drush':
    ensure  => $ensure,
  }

  case $operatingsystem {
    /^(Debian|Ubuntu)$/: {
      include drush::apt
      Package['drush'] { require => Exec['drush_update_apt'] }
    }
  }

  if $dist {

    Package['drush'] { require => Class['drush::apt'] }

    if $api == 4 { $backports = 'squeeze' }
    else { $backports = '' }

    class {'drush::apt':
      dist => $dist,
      backports => $backports,
    }
  }
}

