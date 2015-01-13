<?php

/**
 * @file Provision named context Valkyrie class.
 */

class Provision_Context_Valkyrie extends Provision_Context {

  function init_Valkyrie() {
    if ($options = drush_get_option_list('options', FALSE)) {
      if ($index = array_search('remote_host', $options) && $remote_host = drush_get_option('remote_host', FALSE)) {
        // Setting a 'remote-host' option would cause commands to be run on the
        // remote. So we pass in an option that won't affect operations, in order
        // to set it in the context here as 'remote-host'.
        $this->setProperty('remote-host', $remote_host);
        unset($options[$index]);
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
