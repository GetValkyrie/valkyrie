<?php
/**
 * @file
 * Template file for a local Drushrc config file.
 */
print "<?php \n"; ?>

$options['skip-tables']['dev'] = array(
  'cache',
  'cache_*',
  'flood',
  'history',
  'sessions',
  'users',
  'watchdog',
);

