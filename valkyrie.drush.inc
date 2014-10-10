<?php

/**
 * @file Provides the Valkyrie Drush commands.
 */

require_once(dirname(__FILE__) . '/includes/templates.inc');

/**
 * Implements hook_drush_command().
 */
function valkyrie_drush_command() {
  $items = array();

  $items['valkyrie-new'] = array(
    'description' => "Initialize a new Valkyrie project.",
    'arguments' => array(
      'name' => 'The name of the new project',
    ),
    'options' => array(
      'commit' => 'Commit the project into a new git repo. Defaults to true.',
    ),
    'examples' => array(
      'drush vnew my_new_project --build=false' => 'Create a new project, but do not build a platform from the makefile.',
    ),
    'aliases' => array('vnew'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  return $items;
}

/**
 * Command callback for the 'valkyrie-new' command.
 */
function drush_valkyrie_new($name) {
  if (!drush_confirm(dt('Create platform "'. $name . '"?'))) {
    return drush_user_abort();
  }

  $templates_dir = dirname(__FILE__) . '/templates';

  drush_invoke('make', array("$templates_dir/platform.make", $name));

  $templates = array(
    'platform.info' => "$name/profiles/$name/$name.info",
    'platform.make' => "$name/platform.make",
    'gitignore' => "$name/.gitignore",
  );

  foreach ($templates as $template => $dest_path) {
    valkyrie_template($templates_dir . '/' . $template, $dest_path, array('name' => $name), TRUE);
  }

  if (drush_get_option('commit', TRUE)) {
    drush_shell_cd_and_exec($name, 'git init');
    drush_shell_cd_and_exec($name, 'git add .');
    drush_shell_cd_and_exec($name, 'git commit -m"Initialize new Valkyrie project."');
  }

}
