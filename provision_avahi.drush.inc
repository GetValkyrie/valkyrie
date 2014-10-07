<?php
/**
 * Create Avahi CNAME aliases when installing a site.
 */

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_provision_avahi_post_provision_verify() {
  if (d()->type == 'site' && substr(d()->uri, -6) == '.local') {
    drush_log(dt("Creating Avahi CNAME alias for site."));
    file_put_contents('/var/aegir/config/avahi-aliases', d()->uri . "\n", FILE_APPEND);
    if (drush_shell_exec('sudo /usr/sbin/service avahi-aliases restart')) {
      drush_log(dt("Creatied Avahi alias for !uri", array('!uri' => d()->uri)), 'success');
    }
    else {
      drush_log(dt("Failed to restart Avahi alias service."), 'warning');
    }
  }
}

/**
 * Implements drush_hook_post_COMMAND().
 */
function drush_provision_avahi_post_provision_install() {
  drush_provision_avahi_post_provision_verify();
}
