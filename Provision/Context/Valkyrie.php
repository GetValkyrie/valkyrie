<?php

/**
 * @file Provision named context Valkyrie class.
 */

class Provision_Context_Valkyrie extends Provision_Context {

  function init_Valkyrie() {
    if ($options = drush_map_assoc(drush_get_option_list('options', FALSE))) {
      // TODO: We could instead preprend 'valkyrie_' to options that won't pass
      // cleanly, and then just iterate over those, stripping off the prefix.
      if (array_key_exists('remote_host', $options) && $remote_host = drush_get_option('remote_host', FALSE)) {
        // Setting a 'remote-host' option would cause commands to be run on the
        // remote. So we pass in an option that won't affect operations, in order
        // to set it in the context here as 'remote-host'.
        $this->setProperty('remote-host', $remote_host);
        unset($options['remote_host']);
      }
      if (array_key_exists('ssh_options', $options) && $ssh_options = drush_get_option('ssh_options', FALSE)) {
        // The 'ssh-options' option appears to be unset by Drush. So we pass in
        // an option that will persist, in order to set it in the context here
        // as 'ssh_options'.
        $this->setProperty('ssh-options', $ssh_options);
        unset($options['ssh_options']);
      }

      foreach ($options as $option) {
        if (drush_get_option($option, FALSE)) {
          $this->setProperty($option);
        }
      }
    }
  }

  /**
   * Write out this named context to an alias file.
   */
  function write_alias() {
    $config = new Provision_Config_Drushrc_Valkyrie($this->name, $this->properties);
    drush_log(dt('Writing Valkyrie alias to :path', array(':path' => $config->filename())));
    $config->write();
  }

}
