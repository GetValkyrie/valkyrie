<?php

/**
 * @file Provision named context Valkyrie class.
 */

class Provision_Context_Valkyrie extends Provision_Context {

  function init_Valkyrie() {
    if ($options = drush_get_option_list('options', FALSE)) {
      foreach ($options as $option) {
        if (drush_get_option($option, FALSE)) {
          $this->setProperty($option);
        }
      }
    }
    if ($remote_host = drush_get_option('remote_host', FALSE)) {
      $this->setProperty('remote-host', $remote_host);
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
