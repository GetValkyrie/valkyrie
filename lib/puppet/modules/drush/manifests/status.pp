define drush::status (
  $site_alias = $drush::defaults::site_alias,
  $options    = $drush::defaults::options,
  $arguments  = $drush::defaults::arguments,
  $site_path  = $drush::defaults::site_path,
  $drush_user = $drush::defaults::drush_user,
  $drush_home = $drush::defaults::drush_home,
  $log        = $drush::defaults::log
  ) {

  drush::run {"drush-status:${name}":
    command    => 'core-status',
    site_alias => $site_alias,
    options    => $options,
    arguments  => $arguments,
    site_path  => $site_path,
    drush_user => $drush_user,
    drush_home => $drush_home,
    log        => $log,
  }

}
