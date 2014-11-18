<?php
/**
 * @file Provides the Valkyrie Drush commands.
 */

// Use Composer's autoloader
require_once(dirname(__FILE__) . '/vendor/autoload.php');

define('MAKEFILE_NAME', 'platform.make');
require_once(dirname(__FILE__) . '/includes/templates.inc');

// Only include Aegir hooks when on an Aegir server.
if (function_exists('provision_fqdn')) {
  require_once(dirname(__FILE__) . '/includes/aegir.inc');
}

/**
 * Implements hook_drush_command().
 */
function valkyrie_drush_command() {
  $items = array();

  $items['valkyrie-new'] = array(
    'description' => 'Create a project.',
    'arguments' => array(
      'path' => 'Path to the project (defaults to the current directory).',
    ),
    'options' => array(
      'commit' => 'Commit the project into a new git repo (defaults to true).',
    ),
    'examples' => array(
      'drush vnew my_project' => 'Create a project at ./my_new_project.',
    ),
    'aliases' => array('vnew'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-update'] = array(
    'description' => 'Update a project.',
    'aliases' => array('vup'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-generate-platform'] = array(
    'description' => 'Generate a platform.',
    'arguments' => array(
      'name' => 'Name of the platform.',
    ),
    'required-arguments' => TRUE,
    'options' => array(
      'commit' => 'Commit the platform into a new git repo (defaults to true).',
    ),
    'examples' => array(
      'drush vgp my_platform --build=false' => 'Create a platform but don\'t build it from the makefile.',
    ),
    'aliases' => array('vgp'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-rebuild'] = array(
    'description' => 'Rebuild an existing Valkyrie project.',
    'arguments' => array(
      'path' => 'The path of the project. Defaults to the current directory.',
    ),
    'aliases' => array('vre'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-sql-snapshot'] = array(
    'description' => "Cache a sql-dump for later diff'ing.",
    'aliases' => array('vss'),
    'options' => array(
      'snapshot-file' => 'Specify the file to which to write the snapshot.',
      'snapshot-dir' => 'Specify the directory to which to write snapshots.',
    ),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-sql-diff'] = array(
    'description' => 'Diff the current sql-dump with an earlier snapshot.',
    'aliases' => array('vsd'),
    'options' => array(
      'prompt' => 'Choose from a list of previous snapshots.',
      'diff-cmd' => "Specify the command to use for diff'ing.",
      'snapshot-file' => 'Specify the file containing the snapshot to compare.',
      'snapshot-dir' => 'Specify the directory to search for snapshots.',
    ),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  return $items;
}

/**
 * Command callback for the 'valkyrie-new' command.
 */
function drush_valkyrie_new($path = FALSE) {
  if ($path === FALSE) {
    $prompt = dt('Create a new Valkyrie project in the current directory?');
    if (drush_confirm($prompt)) {
      $path = getcwd();
    }
    else {
      drush_user_abort();
      return;
    }
  }
  else {
    if (is_dir($path) && !is_dir($path . '/.valkyrie')) {
      drush_log(dt('Project directory already exists.'), 'warning');
      $prompt = dt('Proceed with creating a Valkyrie project in the designated directory?');
      if (!drush_confirm($prompt)) {
        drush_user_abort();
        return;
      }
    }
    elseif (is_dir($path . '/.valkyrie')) {
      drush_set_error('VALKYRIE_PROJECT_EXISTS', dt('The project directory already appears to contain Valkyrie code. Try running "drush valkyrie-update" from within the directory to update the Valkyrie code.'));
      return;
    }
    else {
      drush_log(dt('Creating project directory.'));
      drush_mkdir($path);
    }
  }

  drush_log(dt('Copying Valkyrie code into project.'));
  drush_mkdir($path . '/.valkyrie');
  $src = dirname(__FILE__);
  $lib_path = $path . '/.valkyrie/valkyrie';
  drush_copy_dir($src, $lib_path);
  drush_delete_dir($lib_path . '/.git', TRUE);

  $old_path = getcwd();
  chdir($path);
  drush_log(dt('Symlinking .gitignore.'));
  symlink('.valkyrie/valkyrie/vagrant/.gitignore', '.gitignore');
  drush_log(dt('Symlinking Vagrantfile.'));
  symlink('.valkyrie/valkyrie/vagrant/Vagrantfile', 'Vagrantfile');
  chdir($old_path);

  if (drush_get_option('commit', TRUE)) {
  drush_log(dt('Initializing git repo, and committing new platform.'));
    drush_shell_cd_and_exec($path, 'git init');
    drush_shell_cd_and_exec($path, 'git add .');
    drush_shell_cd_and_exec($path, 'git commit -m"Initialize new Valkyrie project."');
  }

  drush_log(dt('Valkyrie project initialized at: :path', array(':path' => $path)), 'ok');
}

/**
 * Command callback for the 'valkyrie-snapshot' command.
 */
function drush_valkyrie_update() {
  $lib_path = getcwd() . '/.valkyrie/valkyrie';
  if (!is_dir($lib_path)) {
    drush_set_error('VALKYRIE_NOT_VALKYRIE_PROJECT', 'This does not appear to be a Valkyrie project.');
    return FALSE;
  }
  $src = dirname(__FILE__);
  $prompt = dt('Update the Valkyrie code in this project (at \'.valkyrie/valkyrie\') with the latest from :src?', array(':src' => $src));
  if (drush_confirm($prompt)) {
    drush_log(dt('Removing existing Valkyrie code.'));
    drush_delete_dir($lib_path, TRUE);
    drush_copy_dir($src, $lib_path);
    drush_delete_dir($lib_path . '/.git', TRUE);
    drush_log(dt('Valkyrie code updated.'), 'ok');
  }
  else {
    drush_user_abort();
    return;
  }
}

/**
 * Command callback for the 'valkyrie-snapshot' command.
 */
function drush_valkyrie_sql_snapshot() {
  $alias = drush_get_context('DRUSH_TARGET_SITE_ALIAS');
  // TODO: move the default snapshot location to a cache directory
  $dir = drush_get_option('snapshot-dir', getcwd() . '/.valkyrie/sql-snapshots');
  if (!is_dir($dir)) {
    drush_mkdir($dir);
  }
  date_default_timezone_set("UTC");
  $filename = drush_get_option('snapshot-file', "$dir/snapshot-$alias-" . date('c'));
  return _drush_valkyrie_sql_snapshot($alias, $filename);
}

function _drush_valkyrie_sql_snapshot($alias, $filename) {
  $options = array(
    'skip-tables-key' => 'dev',
    'data-only' => TRUE,
    'ordered-dump' => TRUE,
  );
  $return = drush_invoke_process($alias, 'sql-dump', array(), $options, array('integrate' => FALSE));
  if ($return === FALSE || $return['error_status']) {
    return drush_set_error('Unable to execute SQL snapshot: ' .  $return['output']);
  }
  return file_put_contents($filename, $return['output']);
}

/**
 * Command callback for the 'valkyrie-snapshot' command.
 */
function drush_valkyrie_sql_diff() {
  $alias = drush_get_context('DRUSH_TARGET_SITE_ALIAS');
  if (drush_get_option('snapshot-file', FALSE)) {
    $snapshot = drush_get_option('snapshot-file');
  }
  else {
    $dir = drush_get_option('snapshot-dir', getcwd() . '/.valkyrie/sql-snapshots');
    $files = array_keys(drush_scan_directory($dir, "/$alias/"));
    if (!count($files)) {
      return drush_set_error('No snapshot file found.');
    }
    sort($files);
    if (drush_get_option('prompt', FALSE)) {
      $choice = drush_choice($files);
      if ($choice === FALSE) {
        return FALSE;
      }
    }
    else {
      $choice = count($files) - 1;
    }
    $snapshot = $files[$choice];
    $filename = drush_tempnam('valkyrie_tmp_sql_dump');
    if (!_drush_valkyrie_sql_snapshot($alias, $filename)) {
      return FALSE;
    }
  }
  $diff_command = drush_get_option('diff-cmd', 'git diff --no-index -U0 --no-prefix');
  drush_shell_proc_open("$diff_command $snapshot $filename");
}

/**
 * Command callback for the 'valkyrie-generate-platform' command.
 */
function drush_valkyrie_generate_platform($name) {
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
    drush_shell_cd_and_exec($name, 'git commit -m "Valkyrie: Generate new platform."');
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

  drush_log('Creating temporary directory.');
  $tempdir = dirname($path) . '/tmp-' . time();
  mkdir($tempdir);

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

  $profile_name = basename($path);
  drush_log('Preserving ' . $profile_name . ' directory.');
  $profile_dir = $path . '/profiles/' . $profile_name;
  $tmp_profile_dir = $tempdir . '/profile';
  if (!is_dir($profile_dir)) {
    drush_set_error('VALKYRIE_REBUILD_NO_PROFILE_PATH',"The profile directory ('$profile_dir') does not exist.");
  }
  drush_move_dir($profile_dir, $tmp_profile_dir);

  drush_log('Preserving makefile.');
  rename($path . '/' . MAKEFILE_NAME, $tempdir . '/' . MAKEFILE_NAME);

  drush_log('Preserving .gitignore.');
  rename("$path/.gitignore", $tempdir . '/gitignore');

  drush_log('Removing old platform.');
  drush_delete_dir_contents($path);

  drush_log('Building new platform');
  $drush_affirmative = drush_get_context('DRUSH_AFFIRMATIVE');
  drush_set_context('DRUSH_AFFIRMATIVE', TRUE);
  drush_invoke('make', array($tempdir . '/' . MAKEFILE_NAME));
  drush_set_context('DRUSH_AFFIRMATIVE', $drush_affirmative);

  drush_log('Restoring sites directory.');
  drush_move_dir("$sites_dir/all", "$tmp_sites_dir/all");
  drush_move_dir("$sites_dir/default", "$tmp_sites_dir/default");
  drush_move_dir($tmp_sites_dir, $sites_dir, TRUE);

  drush_log('Restoring .git directory.');
  drush_move_dir($tmp_git_dir, $git_dir, TRUE);

  drush_log("Restoring '$profile_name' profile directory.");
  drush_move_dir($tmp_profile_dir, $profile_dir, TRUE);

  drush_log('Restoring .gitignore.');
  rename($tempdir . '/gitignore', "$path/.gitignore");

  drush_log('Restoring makefile.');
  rename($tempdir . '/' . MAKEFILE_NAME, $path . '/' . MAKEFILE_NAME);

  drush_log('Removing temporary directory');
  rmdir($tempdir);

  drush_log('Platform rebuild complete.', 'ok');
}
