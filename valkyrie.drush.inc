<?php

/**
 * @file Provides the Valkyrie Drush commands.
 */

define('MAKEFILE_NAME', 'platform.make');
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
    'required-arguments' => TRUE,
    'options' => array(
      'commit' => 'Commit the project into a new git repo. Defaults to true.',
    ),
    'examples' => array(
      'drush vnew my_new_project --build=false' => 'Create a new project, but do not build a platform from the makefile.',
    ),
    'aliases' => array('vnew'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-rebuild'] = array(
    'description' => "Rebuild an existing Valkyrie project.",
    'arguments' => array(
      'path' => 'The path of the project. Defaults to the current directory.',
    ),
    'aliases' => array('vre'),
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

  $result = drush_invoke('make', array("$templates_dir/platform.make", $name));

  drush_log(dt('Adding default files.'), 'ok');
  $templates = array(
    'platform.info' => "$name/profiles/$name/$name.info",
    MAKEFILE_NAME => $name. '/' . MAKEFILE_NAME,
    'gitignore' => "$name/.gitignore",
    'platform.profile' => "$name/profiles/$name/$name.profile",
    'platform.install' => "$name/profiles/$name/$name.install",
  );
  foreach ($templates as $template => $dest_path) {
    valkyrie_template($templates_dir . '/' . $template, $dest_path, array('name' => $name), TRUE);
  }

  drush_log(dt('Initializing git repo, and committing new platform.'), 'ok');
  if (drush_get_option('commit', TRUE)) {
    drush_shell_cd_and_exec($name, 'git init');
    drush_shell_cd_and_exec($name, 'git add .');
    drush_shell_cd_and_exec($name, 'git commit -m"Initialize new Valkyrie project."');
  }

}

/**
 * Command callback for the 'valkyrie-rebuild' command.
 */
function drush_valkyrie_rebuild($path = FALSE) {
  if (!$path) {
    if (!drush_confirm(dt('Rebuild the platform in the current directory?'))) {
      return drush_user_abort();
    }
    $path = getcwd();
  }
  if (!is_dir($path)) {
    drush_set_error('VALKYRIE_REBUILD_NO_PLATFORM_PATH',"The specified path ('$path') does not exist or is not a directory.");
  }

  drush_log('Beginning platform rebuild.', 'ok');
  $tempdir = drush_tempdir();

  drush_log('Preserving sites directory.');
  $sites_dir = $path . '/sites';
  $tmp_sites_dir = $tempdir . '/sites';
  if (!is_dir($sites_dir)) {
    drush_set_error('VALKYRIE_REBUILD_NO_SITES_PATH',"The sites directory in the specified platform ('$sites_dir') does not exist.");
  }
  drush_move_dir($sites_dir, $tmp_sites_dir);

  drush_log('Removing sites/all and sites/default');
  drush_delete_dir("$tmp_sites_dir/all");
  drush_delete_dir("$tmp_sites_dir/default");

  drush_log('Preserving .git directory.');
  $git_dir = $path . '/.git';
  $tmp_git_dir = $tempdir . '/.git';
  if (!is_dir($git_dir)) {
    drush_set_error('VALKYRIE_REBUILD_NO_GIT_PATH',"The .git directory in the specified platform ('$git_dir') does not exist.");
  }
  drush_move_dir($git_dir, $tmp_git_dir);

  drush_log('Preserving makefile.');
  rename($path . '/' . MAKEFILE_NAME, $tempdir . '/' . MAKEFILE_NAME);

  drush_log('Preserving .gitignore.');
  rename("$path/.gitignore", $tempdir . '/gitignore');

  drush_log('Removing old platform.');
  drush_delete_dir_contents($path);

  drush_log('Building new platform');
  $drush_affirmative = drush_get_context('DRUSH_AFFIRMATIVE');
  drush_set_context('DRUSH_AFFIRMATIVE', FALSE);
  drush_invoke('make', array($tempdir . '/' . MAKEFILE_NAME));
  drush_set_context('DRUSH_AFFIRMATIVE', $drush_affirmative);

  drush_log('Restoring sites directory.');
  drush_copy_dir($tmp_sites_dir, $sites_dir, TRUE);

  drush_log('Restoring .git directory.');
  drush_copy_dir($tmp_git_dir, $git_dir, TRUE);

  drush_log('Restoring .gitignore.');
  rename($tempdir . '/gitignore', "$path/.gitignore");

  drush_log('Restoring makefile.');
  rename($tempdir . '/' . MAKEFILE_NAME, $path . '/' . MAKEFILE_NAME);

  drush_log('Platform rebuild complete.', 'ok');
}
