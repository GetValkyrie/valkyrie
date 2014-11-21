<?php
/**
 * @file Create Avahi CNAME aliases when installing a site.
 */

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_provision_avahi_post_provision_verify() {
  if (d()->type == 'site' && d()->profile != 'hostmaster' && d()->uri != provision_fqdn()) {
    $alias_path = drush_get_option('avahi_alias_path', '/var/aegir/config/avahi-aliases');

    // Use an automatically generated URL alias, if available
    $aliases = d()->aliases;
    if (count($aliases)) {
      $site_name = $aliases[0];
    }
    else {
      $site_name = d()->uri;
    }

    if ( substr($site_name, -6) != '.local') {
      drush_log(dt("Only domains ending in '.local' are supported. Could not create Avahi alias for !uri", array('!uri' => $site_name)));
      return;
    }
    if (!is_dir($alias_path)) {
      drush_log(dt("Creating Avahi alias directory."));
      mkdir($alias_path, 0700);
    }
    drush_log(dt("Creating Avahi CNAME alias for site."));
    file_put_contents($alias_path . '/' . $site_name, $site_name);
    if (drush_shell_exec('sudo /usr/bin/supervisorctl restart avahi-aliases')) {
      drush_log(dt("Created Avahi alias for !uri", array('!uri' => $site_name)), 'success');
    }
    else {
      drush_log(dt("Failed to restart Avahi alias service."), 'warning');
    }
  }
  // Make sure we don't have a site alias matching the server's FQDN.
  if (d()->type == 'site' && d()->uri == provision_fqdn()) {
    _drush_provision_avahi_remove_alias(d()->uri);
  }
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_provision_avahi_post_provision_install() {
  drush_provision_avahi_post_provision_verify();
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_provision_avahi_post_provision_delete() {
  if (d()->type == 'site') {
    _drush_provision_avahi_remove_alias(d()->uri);
  }
}

function _drush_provision_avahi_remove_alias($uri) {
  $aliases_dir = drush_get_option('avahi_alias_path', '/var/aegir/config/avahi-aliases');
  $alias_path = $aliases_dir . '/' . $uri;
  if (file_exists($alias_path)) {
    drush_log(dt("Removing Avahi CNAME alias for site."));
    unlink($alias_path);
    if (drush_shell_exec('sudo /usr/bin/supervisorctl restart avahi-aliases')) {
      drush_log(dt("Removed Avahi alias for !uri", array('!uri' => $uri)), 'success');
    }
    else {
      drush_log(dt("Failed to restart Avahi alias service."), 'warning');
    }
  }
}
