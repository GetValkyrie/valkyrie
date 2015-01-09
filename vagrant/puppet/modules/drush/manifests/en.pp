define drush::en (
  $site_alias  = $drush::defaults::site_alias,
  $options     = $drush::defaults::options,
  $arguments   = $drush::defaults::arguments,
  $drush_user  = $drush::defaults::drush_user,
  $drush_home  = $drush::defaults::drush_home,
  $log         = $drush::defaults::log,
  ) {

  if $arguments { $real_args = $arguments }
  else { $real_args = $name }

  drush::run {"drush-en:${name}":
    command     => 'pm-enable',
    site_alias  => $site_alias,
    options     => $options,
    arguments   => $real_args,
    drush_user  => $drush_user,
    drush_home  => $drush_home,
    log         => $log,
    notify      => Drush::Run["drush-cc-drush:${name}"],
    unless      => "drush ${site_alias} pm-list --status=enabled | grep ${name}",
  }

  # Drush appears to cache the enabled status of modules...
  drush::run {"drush-cc-drush:${name}":
    command     => 'cache-clear drush',
    site_alias  => $site_alias,
    drush_user  => $drush_user,
    drush_home  => $drush_home,
    refreshonly => true,
    log         => $log,
  }

}
