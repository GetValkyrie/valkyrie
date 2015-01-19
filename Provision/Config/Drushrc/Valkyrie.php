<?php
/**
 * @file
 * Provides the Provision_Config_Drushrc_Valkyrie class.
 */

/**
 * Class to write an alias records.
 */
class Provision_Config_Drushrc_Valkyrie extends Provision_Config_Drushrc_Alias {
  public $template = 'provision_drushrc_alias.tpl.php';

  function filename() {
    return drush_server_home() . '/.cache/aliases/' . $this->data['aliasname'] . '.alias.drushrc.php';
  }
}
