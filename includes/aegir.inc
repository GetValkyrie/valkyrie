<?php

/**
 * @file Hooks to modify Aegir's operations.
 */

define('VALKYRIE_FEATURES_EXPORT_PATH', 'sites/all/modules/custom');

/**
 * Implements hook_provision_drupal_config().
 */
function valkyrie_provision_drupal_config($uri, $data) {
  // Set the features export path.
  return "\$conf['features_default_export_path'] = '" . VALKYRIE_FEATURES_EXPORT_PATH . "';";
}

/**
 * Implements hook_provision_drupal_create_directories_alter().
 */
function valkyrie_provision_drupal_create_directories_alter(&$mkdir, $url) {
  drush_log('Setting the features export path (' . VALKYRIE_FEATURES_EXPORT_PATH . ') to be group-writeable.');
  $mkdir[VALKYRIE_FEATURES_EXPORT_PATH] = 02770;
}

/**
 * Implements hook_provision_drupal_chgrp_directories_alter().
 */
function valkyrie_provision_drupal_chgrp_directories_alter(&$chgrp, $url) {
  $web_group = d('@server_master')->web_group;
  drush_log('Setting the features export path (' . VALKYRIE_FEATURES_EXPORT_PATH . ") group to the web user ($web_group)");
  $chgrp[VALKYRIE_FEATURES_EXPORT_PATH] = $web_group;
}

