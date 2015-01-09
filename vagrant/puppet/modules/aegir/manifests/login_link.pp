class aegir::login_link (
  $force = false
  ) inherits aegir::defaults {

  drush::run {'hostmaster login link':
    command     => 'uli',
    loglevel    => 'alert',
    refreshonly => !$force,
  }

}
