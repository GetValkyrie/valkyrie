<?php

/**
 * @file Provides the Valkyrie Drush commands.
 */

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
      'build' => 'Build the resulting platform. Defaults to true.',
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


}
