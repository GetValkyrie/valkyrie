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
  drush_log("Setting the features export path (sites/$uri/modules/custom) to be group-writeable.");
  $mkdir["sites/$uri/modules/custom"] = 02770;
}

/**
 * Implements hook_provision_drupal_chgrp_directories_alter().
 */
function valkyrie_provision_drupal_chgrp_directories_alter(&$chgrp, $url) {
  $web_group = d('@server_master')->web_group;
  drush_log("Setting the features export path (sites/$uri/modules/custom) group to the web user ($web_group)");
  $chgrp["sites/$uri/modules/custom"] = $web_group;
}

