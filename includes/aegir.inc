<?php

/**
 * @file Hooks to modify Aegir's operations.
 */

/**
 * Implements hook_provision_drupal_config().
 */
function valkyrie_provision_drupal_config($uri, $data) {
  // Set the features export path.
  return "\$conf['features_default_export_path'] = 'sites/$uri/modules/custom';";
}

/**
 * Implements hook_provision_drupal_create_directories_alter().
 */
function valkyrie_provision_drupal_create_directories_alter(&$mkdir, $url) {
  drush_log("Setting the features export path (sites/$url/modules/custom) to be group-writeable.");
  $mkdir["sites/$url/modules/custom"] = 02660;
}

/**
 * Implements hook_provision_drupal_chgrp_directories_alter().
 */
function valkyrie_provision_drupal_chgrp_directories_alter(&$chgrp, $url) {
  $web_group = d('@server_master')->web_group;
  drush_log("Setting the features export path (sites/$url/modules/custom) group to the web user ($web_group)");
  $chgrp["sites/$url/modules/custom"] = $web_group;
}

