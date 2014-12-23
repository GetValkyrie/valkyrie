<?php

/**
 * @file Hooks to modify Aegir's operations.
 */

define('AEGIR_FRONTEND_URL', provision_fqdn());
define('VALKYRIE_ALIASES_PATH', '/var/aegir/config/valkyrie_aliases');

/**
 * Implements hook_provision_drupal_config().
 */
function valkyrie_provision_drupal_config($url, $data) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    drush_log('Setting default features export path.');
    return "\$conf['features_default_export_path'] = 'sites/$url/modules/custom';";
  }
}

/**
 * Implements hook_provision_drupal_create_directories_alter().
 */
function valkyrie_provision_drupal_create_directories_alter(&$mkdir, $url) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    drush_log("Setting the features export path (sites/$url/modules/custom) to be group-writeable.");
    $mkdir["sites/$url/modules/custom"] = 02770;
    $profile = d()->profile;
    drush_log("Setting the profile module path (profiles/$profile/modules/custom) to be group-writeable.");
    $mkdir["profiles/$profile/modules"] = 02770;
  }
}

/**
 * Implements hook_provision_drupal_chmod_not_recursive_directories_alter().
 */
function valkyrie_provision_drupal_chmod_not_recursive_alter(&$chmod_not_recursive, $url) {
  if (!in_array($url, array('all', AEGIR_FRONTEND_URL))) {
    drush_log("Stopping recursion into custom Features modules on chmod operations.");
    $chmod_not_recursive[] = "sites/$url/modules/custom";
    $chmod_not_recursive[] = "profiles/$url/modules/custom";
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
 * Allow the web user to write to custom features.
 *
 * WARNING: This is insecure, and *MUST ONLY BE USED IN DEVELOPMENT* 
 */
function _valkyrie_fix_dev_perms() {
  // Only run on hosted sites, not the Aegir front-end.
  if (d()->profile != 'hostmaster') {
    $path = d()->site_path . '/modules/custom';
    $group = d('@server_master')->web_group;
    drush_log('Ensuring custom features can be exported directly from the site.');
    provision_file()->chgrp($path, $group)
      ->succeed('Changed group ownership of <code>@path</code> to @gid')
      ->fail('Could not change group ownership <code>@path</code> to @gid');
    // Sites appear to be cloned as 555, making it impossible to delete them.
    // TODO: Move this into hosting_git? Figure out why it's happening in the
    // first place.
    drush_log('Ensuring proper permissions on site path.');
    provision_file()->chmod(d()->site_path, 0755)
      ->succeed('Changed permissions of @path to @perm')
      ->fail('Could not change permissions of @path to @perm');
  }
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_verify() {
  if (d()->type == 'site') {
    _drush_valkyrie_create_site_alias();
    if (d()->profile == 'hostmaster') {
      _drush_valkyrie_create_server_alias();
    }
    _valkyrie_fix_dev_perms();
    _valkyrie_add_default_drushrc();
  }
}

/**
 * Helper function to determine the site alias name.
 */
function _drush_valkyrie_get_site_aliasname() {
  $aliases = d()->aliases;
  if (count($aliases)) {
    return $aliases[0];
  }
  elseif (d()->profile == 'hostmaster') {
    return d()->uri;
  }
  else {
    drush_log(dt('No URL aliases were defined for :name. Skipping Valkyrie alias creation.', array(':name' => d()->name)));
    return FALSE;
  }
}

/**
 * Helper function to create site aliases for use on the host.
 */
function _drush_valkyrie_create_site_alias() {
  if ($aliasname = _drush_valkyrie_get_site_aliasname()) {
    $options = array(
      'remote_host' => provision_fqdn(d()->server->remote_host),
      'remote-user' => d()->server->script_user,
      'uri' => $aliasname,
      'root' => d()->root,
      'alias' => d()->name,
    );
    drush_valkyrie_create_alias($aliasname, $options);
  }
}

/**
 * Helper function to create a server alias for use on the host.
 */
function _drush_valkyrie_create_server_alias() {
  $options = array(
    'remote_host' => provision_fqdn(d()->server->remote_host),
    'remote-user' => d()->server->script_user,
    'uri' => provision_fqdn(d()->server->remote_host),
  );
  drush_valkyrie_create_alias(gethostname(), $options);
}

/**
 * Create an alias with arbitrary options.
 */
function drush_valkyrie_create_alias($aliasname, $options) {
  // Let Provision_Context_Valkyrie know which options to write to the alias.
  $options['options'] = implode(',',array_keys($options));
  $options['context_type'] = 'Valkyrie';
  drush_log(dt('Creating Valkyrie alias `:alias`',array(':alias' => $aliasname)));
  provision_backend_invoke('@hostmaster', 'provision-save', array($aliasname), $options);
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_install() {
  // Sites are not verified on install, so run our hook here.
  drush_valkyrie_post_provision_verify();
}

/**
 * Implements drush_hook_pre_COMMAND().
 */
function drush_valkyrie_pre_provision_reinstall() {
  // Run a 'git pull' on the site, so that we install on the latest code.
  drush_log('Pulling Git repo before reinstall.');
  #drush_invoke('provision-git-pull');
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_reinstall() {
  // TODO: Move this to a hook_post_hosting_TASK_TYPE_task() in a front-end
  // module? If we can get aliases to persist across reinstalls, this would
  // better allow for a headless Valkyrie.

  // Run a verify on the site, so that we get back our aliases, etc.
  drush_log('Verify site after reinstall.');
  drush_invoke_process('@hostmaster', 'hosting-task', array(d()->name, 'verify'));
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_valkyrie_post_provision_delete() {
  // Remove the alias we generated.
  _drush_valkyrie_delete_alias();
}

/**
 * Helper function to delete aliases generated for use on the host.
 */
function _drush_valkyrie_delete_alias() {
  $aliasname = _drush_valkyrie_get_site_aliasname();
  $alias_path = VALKYRIE_ALIASES_PATH . "/$aliasname.alias.drushrc.php";
  if (file_exists($alias_path)) {
    if (unlink($alias_path)) {
      drush_log('Deleted Drush alias for Valkyrie.', 'ok');
    }
    else {
      drush_log('Failed to delete Drush alias for Valkyrie.', 'warning');
    }
  }
  else {
    drush_log('Failed to find a Drush alias for Valkyrie to delete.', 'warning');
  }
}

/**
 * Helper function to create local.drushrc.php for site.
 */
function _valkyrie_add_default_drushrc() {
  $dest_path = d()->site_path . '/local.drushrc.php';
  if (file_exists($dest_path)) {
    drush_log('Local Drushrc file already exists at: ' . $dest_path, 'ok');
  }
  else {
    $template_path = dirname(dirname(__FILE__)) . '/templates/drushrc.tpl.php';
    if (valkyrie_template($template_path, $dest_path)) {
      drush_log('Created local Drushrc file for Valkyrie.', 'ok');
    }
    else {
      drush_log('Failed to create Drush alias for Valkyrie.', 'warning');
    }
  }
}

/**
 * Implements drush_hook_pre_COMMAND().
 *
 * TODO: Why can't we pass in 'client_email' in the $options array in
 * drush_valkyrie_clone_site()?
 */
function drush_valkyrie_pre_provision_install_backend() {
  drush_set_option('client_email', 'me@example.com');
}
