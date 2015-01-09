<?php
/**
 * @file Provides the Skynet Drush hooks.
 */

require_once(dirname(__FILE__) . '/includes/templates.inc');

/**
 * Implements drush_hook_post_COMMAND().
 *
 * Whenever we migrate the hostmaster site, we need to re-write the skynet
 * config file with the new DB credentials, and restart the service.
 */
function drush_skynet_post_provision_migrate() {
  if (d()->type == 'site' && d()->profile == 'hostmaster') {
    _drush_skynet_create_config();
    _drush_skynet_restart_service();
  }
}

/**
 * Implements drush_hook_post_COMMAND().
 *
 * When we install the hostmaster site, we need to write the skynet config file
 * with the DB credentials, and start the service.
 */
function drush_skynet_post_provision_install() {
  if (d()->type == 'site' && d()->profile == 'hostmaster') {
    drush_skynet_post_provision_migrate();
  }
}

/**
 * Helper function to write the skynet config file.
 */
function _drush_skynet_create_config() {
  $template_path = dirname(__FILE__) . '/templates/skynet.conf.tpl.php'; 
  $dest_path = '/var/aegir/config/skynet.conf';
  $site_context = drush_get_context('site');
  $variables = array(
    'host' => $site_context['db_host'],
    'db' => $site_context['db_name'], 
    'user' => $site_context['db_user'], 
    'passwd' => $site_context['db_passwd'],     
  );
  skynet_template($template_path, $dest_path, $variables, TRUE);
}

/**
 * Helper function to restart the skynet service.
 */
function _drush_skynet_restart_service() {
  if (drush_shell_exec('sudo supervisorctl restart skynet-queue')) {
    drush_log('Restarted Skynet queue service.');
  }
  else {
    drush_set_error('SKYNET_ERROR_RESTARTING_SERVICE', dt("An error occurred restarting the Skynet queue service. The command output follows:\n :output", array(':output' => drush_shell_exec_output())));
  }
}
 
