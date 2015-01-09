define drush::make (
  $makefile,
  $make_path  = false,
  $options    = $drush::defaults::options,
  $site_path  = $drush::defaults::site_path,
  $drush_user = $drush::defaults::drush_user,
  $drush_home = $drush::defaults::drush_home,
  $log        = $drush::defaults::log
  ) {

  if $make_path { $real_make_path = $make_path }
  else { $real_make_path = $name }
  $arguments = "${makefile} ${real_make_path}"

  drush::run {"drush-make:${name}":
    command    => 'make',
    site_alias => '@none',
    creates    => $make_path,
    options    => $options,
    arguments  => $arguments,
    drush_user => $drush_user,
    drush_home => $drush_home,
    log        => $log,
    timeout    => 0,
  }

}
