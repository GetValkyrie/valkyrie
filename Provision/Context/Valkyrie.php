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
  }

  /**
   * Write out this named context to an alias file.
   */
  function write_alias() {
    $config = new Provision_Config_Drushrc_Valkyrie($this->name, $this->properties);
    $config->write();
  }

}
