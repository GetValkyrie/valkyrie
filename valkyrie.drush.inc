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
  if (!drush_confirm(dt('Create platform "'. $name . '"?'))) {
    return drush_user_abort();
  }

  if(!drush_mkdir($name)) {
    return;
  };

  $templates_dir = dirname(__FILE__) . '/templates';

  $templates = array_diff(scandir($templates_dir), array('..', '.'));

  foreach ($templates as $template) {
    valkyrie_template($templates_dir . '/' . $template, $name . '/' . $template, array('name' => $name));
  }

}

/**
 * Write a file based on a template.
 */
function valkyrie_template($template_path, $dest_path, $variables = array()) {
  $contents = _valkyrie_render_template(_valkyrie_load_template($template_path), $variables);
  if (!file_exists($dest_path)) {
    file_put_contents($dest_path, $contents);
    return;
  }
  drush_set_error('VALKYRIE_FILE_EXISTS', 'The specified destination file already exists.');
}

/**
 * Load a template file.
 */
function _valkyrie_load_template($template_path) {
  if (file_exists($template_path) && is_readable($template_path)) {
    drush_log("Template loaded: $template_path");
    return file_get_contents($template_path);
  }
  drush_set_error('VALKYRIE_MISSING_TEMPLATE', 'The specified template file is either missing or un-readable.');
}

/**
 * Render template, making variables available from $variables associative array.
 *
 * Copied from Aegir's Provision_Config::render_template().
 */
function _valkyrie_render_template($template, $variables) {
  drush_errors_off();
  extract($variables, EXTR_SKIP); // Extract the variables to a local namespace
  ob_start(); // Start output buffering
  eval('?>' . $template); // Generate content
  $contents = ob_get_contents(); // Get the contents of the buffer
  ob_end_clean(); // End buffering and discard
  drush_errors_on();
  return $contents; // Return the contents
}
