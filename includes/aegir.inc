<?php

/**
 * @file Hooks to modify Aegir's operations.
 */

define('AEGIR_FRONTEND_URL', 'aegir3.local');

/**
 * Implements hook_provision_drupal_config().
 */
function valkyrie_provision_drupal_config($uri, $data) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    drush_log('Setting default features export path.');
    return "\$conf['features_default_export_path'] = 'sites/$uri/modules/custom';";
  }
}

/**
 * Implements hook_provision_drupal_create_directories_alter().
 */
function valkyrie_provision_drupal_create_directories_alter(&$mkdir, $url) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    drush_log("Setting the features export path (sites/$url/modules/custom) to be group-writeable.");
    $mkdir["sites/$url/modules/custom"] = 02770;
  }
}

/**
 * Implements hook_provision_drupal_non_recursive_directories_alter().
 */
function valkyrie_provision_drupal_non_recursive_directories_alter(&$non_recursive, $url) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    $non_recursive[] = "sites/$url/modules/custom";
  }
}

/**
 * Implements hook_provision_drupal_chgrp_directories_alter().
 */
function valkyrie_provision_drupal_chgrp_directories_alter(&$chgrp, $url) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    $web_group = d('@server_master')->web_group;
    drush_log("Setting the features export path (sites/$url/modules/custom) group to the web user ($web_group)");
    $chgrp["sites/$url/modules/custom"] = $web_group;
  }
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_verify() {
  if (d()->type == 'site') {
    $aliasname = d()->uri;
    $template_path = dirname(dirname(__FILE__)) . '/templates/drush_alias.tpl.php';
    $dest_path = "/var/aegir/aliases/$aliasname.alias.drushrc.php";
    $variables = array(
      'aliasname' => $aliasname,
      'options' => array(
        'remote-host' => 'aegir3.local',
        'remote-user' => 'aegir',
        'root' => d()->root,
        'uri' => d()->uri,
      ),
    );
    if (valkyrie_template($template_path, $dest_path, $variables, TRUE)) {
      drush_log('Created Drush alias for Valkyrie.', 'ok');
    }
    else {
      drush_log('Failed to create Drush alias for Valkyrie.', 'warning');
    }
  }

}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_install() {
  // Sites are not verified on install, so run our hook here.
  drush_valkyrie_post_provision_verify();
}
