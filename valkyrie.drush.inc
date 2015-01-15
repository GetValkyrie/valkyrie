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
 * Implements hook_drush_init().
 */
function valkyrie_drush_init() {
  $command = drush_get_command();
  if (isset($command['requires_vagrant'])) {
    // Load our cached data.
    $checks = array(
      'vagrant_installed',
      'vagrant_plugins_installed',
    );
    $cache = drush_cache_get_multiple($checks, 'valkyrie');
    // Check if Vagrant is installed.
    if (!$cache['vagrant_installed']) {
      // TODO: We should probably check for a minimum version of Vagrant,
      // rather than just its presence.
      $vagrant_path = drush_shell_exec_output(drush_shell_exec('which vagrant'));
      if (!count($vagrant_path)) {
        drush_die(dt("You have installed Valkyrie, which depends on Vagrant.\nBut Vagrant does not appear to be installed.\nPlease install Vagrant (http://vagrantup.com/) before continuing."));

      }
      else {
        drush_cache_set('vagrant_installed', TRUE, 'valkyrie', DRUSH_CACHE_PERMANENT);
      }
    }
    // Check if Vagrant plugins are installed.
    if (!$cache['vagrant_plugins_installed']) {
      // TODO: load this array from a YAML file, so we can maintain a single
      // source of truth for required plugins. We can then re-use this list
      // when checking from the Vagrantfile.
      $required = array(
        'vagrant-bindfs',
        'vagrant-triggers',
      );
      $vagrant_plugins = drush_shell_exec_output(drush_shell_exec('vagrant plugin list'));
      foreach ($vagrant_plugins as $haystack) {
        foreach ($required as $index => $needle) {
          // TODO: We may need to require minimal versions of certain plugins.
          // We could maintain a hash of 'name' => 'version' for plugins, and
          // check that here, since versions are also listed in the output.
          if (strpos($haystack, $needle) !== FALSE) {
            unset($required[$index]);
            break;
          }
        }
      }
      if (count($required)) {
        drush_die(dt("Valkyrie requires some Vagrant plugins to operate properly. The following plugins were not found on your system (using 'vagrant plugin list'), and will need to be installed to proceed: " .  implode(',', $required)));
      }
      else {
        drush_cache_set('vagrant_plugins_installed', TRUE, 'valkyrie', DRUSH_CACHE_PERMANENT);
      }
    }
  }

  // Register our config and context classes for autoloading.
  valkyrie_provision_register_autoload();
}

/**
 * Register our directory as a place to find Provision classes.
 *
 * This allows Provision to autoload our classes, so that we don't need to
 * specifically include the files before we use the class.
 */
function valkyrie_provision_register_autoload() {
  static $loaded = FALSE;
  if (!$loaded && function_exists('provision_autoload_register_prefix')) {
    $loaded = TRUE;
    provision_autoload_register_prefix('Provision_', dirname(__FILE__));
  }
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
      'up' => 'Launch the VM immediately (defaults to true).',
    ),
    'examples' => array(
      'drush vnew my_project' => 'Create a project at ./my_new_project.',
    ),
    'aliases' => array('vnew'),
    'requires_vagrant' => TRUE,
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-update'] = array(
    'description' => 'Update a project.',
    'options' => array(
      'upstream' => 'Update the global Valkyrie extension with code from a project.',
    ),
    'aliases' => array('vup'),
    'bootstrap' => DRUSH_BOOTSTRAP_DRUSH, // No bootstrap at all.
  );

  $items['valkyrie-platform-generate'] = array(
    'description' => 'Generate a platform.',
    'arguments' => array(
      'name' => 'Name of the platform.',
    ),
    'required-arguments' => 1,
    'options' => array(
      'verify' => 'Verify (and build) the platform before importing it into Aegir.',
      'makefile' => "A makefile from which to build the platform. If not specified, one will be generated.",
      'profile' => 'An install profile to include in a generated platform. This option will be ignored if the --makefile option was specified.'
    ),
    'examples' => array(
      'drush vpg my_platform platform.make' => 'Create a platform built from the provided makefile.',
    ),
    'aliases' => array('vpg'),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-platform-rebuild'] = array(
    'description' => "Rebuild a site's platform.",
    'examples' => array(
      'drush @site.local vpr' => 'Rebuild the platform that the @site.local site is built atop.',
    ),
    'aliases' => array('vpr'),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
  );

  $items['valkyrie-site-clone'] = array(
    'description' => 'Clone a site from a git repo.',
    'arguments' => array(
      'URL' => 'The URL at which to create the site. Use of the production domain (e.g., example.com) is recommended. A local alias (e. g., example-com.local) will be created for you.',
      'git repo' => "The git repo from which to clone this site's configuration.",
    ),
    'required-arguments' => TRUE,
    'options' => array(
      'enable' => 'The name of one or more Features (or modules) to enable post-install.',
      'branch' => 'The git branch to clone.',
      'profile' => 'The profile with which to install the site.',
    ),
    'examples' => array(
      'drush vsc example.com http://github.com/example/example.com' => 'Install a site from the configration provided in the provided git repo.',
    ),
    'aliases' => array('vsc'),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-site-reinstall'] = array(
    'description' => 'Reinstall a site.',
    'examples' => array(
      'drush @example-com.local vsr' => 'Delete and then reinstall a site.',
    ),
    'aliases' => array('vsr'),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-site-generate'] = array(
    'description' => 'Create and install a new git-based site.',
    'arguments' => array(
      'URL' => 'The URL at which to create the site. Use of the production domain (e.g., example.com) is recommended. A local alias (e. g., example-com.local) will be created for you.',
    ),
    'required-arguments' => 1,
    'options' => array(
      'profile' => 'An installation profile with which to install the site.',
      'makefile' => "A makefile from which to build the site's platform.",
    ),
    'examples' => array(
      'drush vsg example.com --makefile=example.make' => 'Install a site built on a platform using the provided makefile.',
    ),
    'aliases' => array('vsg'),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-db-snapshot'] = array(
    'description' => "Cache a sql-dump for later diff'ing.",
    'aliases' => array('vds'),
    'options' => array(
      'snapshot-file' => 'Specify the file to which to write the snapshot.',
      'snapshot-dir' => 'Specify the directory to which to write snapshots.',
    ),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-db-diff'] = array(
    'description' => 'Diff the current sql-dump with an earlier snapshot.',
    'aliases' => array('vdd'),
    'options' => array(
      'prompt' => 'Choose from a list of previous snapshots.',
      'diff-cmd' => "Specify the command to use for diff'ing.",
      'snapshot-file' => 'Specify the file containing the snapshot to compare.',
      'snapshot-dir' => 'Specify the directory to search for snapshots.',
    ),
    'bootstrap' => DRUSH_BOOTSTRAP_NONE,
    'handle-remote-commands' => TRUE,
  );

  $items['valkyrie-logs'] = array(
    'description' => 'Tail the Apache error log.',
    'aliases' => array('vlog'),
    'arguments' => array(
      'log-file' => 'Log file to tail (optional, defaults to /var/log/apache2/error.log).'
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

  if (drush_get_option('up', TRUE)) {
    drush_log(dt('Launching new project VM.'));
    chdir($path);
    drush_shell_proc_open('vagrant up');
    // Wait for import/verify tasks to complete, or they might fail during the
    // reload that follows.
    _valkyrie_wait_for_queue();
    // We need to reload in order for bindfs mounts to work.
    drush_shell_proc_open('vagrant reload');
    // We need to run the inline shell provisioner in order to re-generate the
    // Valkyrie aliases.
    drush_shell_proc_open('vagrant provision --provision-with shell');
  }
}

/**
 * Command callback for the 'valkyrie-update' command.
 */
function drush_valkyrie_update() {
  $lib_path = getcwd() . '/.valkyrie/valkyrie';
  if (!is_dir($lib_path)) {
    drush_set_error('VALKYRIE_NOT_VALKYRIE_PROJECT', 'This does not appear to be a Valkyrie project.');
    return FALSE;
  }
  $src = dirname(__FILE__);
  if (drush_get_option('upstream', FALSE)) {
    $prompt = dt('Update the global Valkyrie extension with the code in this project?');
    if (drush_confirm($prompt)) {
      drush_copy_dir($lib_path, $src, FILE_EXISTS_MERGE);
      drush_log(dt('Valkyrie extension updated.'), 'ok');
    }
  }
  else {
    $prompt = dt('Update the Valkyrie code in this project (at \'.valkyrie/valkyrie\') with the latest from :src?', array(':src' => $src));
    if (drush_confirm($prompt)) {
      drush_copy_dir($src, $lib_path, FILE_EXISTS_OVERWRITE);
      drush_delete_dir($lib_path . '/.git', TRUE);
      drush_log(dt('Valkyrie code updated.'), 'ok');
    }
    else {
      drush_user_abort();
      return;
    }
  }
}

/**
 * Command callback for the 'valkyrie-snapshot' command.
 */
function drush_valkyrie_db_snapshot() {
  $alias = drush_get_context('DRUSH_TARGET_SITE_ALIAS');
  $dir = drush_get_option('snapshot-dir', getcwd() . '/.valkyrie/cache/sql-snapshots');
  if (!is_dir($dir)) {
    drush_mkdir($dir);
  }
  date_default_timezone_set("UTC");
  $filename = drush_get_option('snapshot-file', "$dir/snapshot-$alias-" . date('c'));
  return _drush_valkyrie_db_snapshot($alias, $filename);
}

/**
 * Wrapper to call sql-dump on remote site.
 */
function _drush_valkyrie_db_snapshot($alias, $filename) {
  $options = array(
    'skip-tables-key' => 'dev',
    'data-only' => TRUE,
    'ordered-dump' => TRUE,
  );
  $return = drush_invoke_process($alias, 'sql-dump', array(), $options, array('integrate' => FALSE));
  if ($return === FALSE || $return['error_status']) {
    return drush_set_error('Unable to execute database snapshot: ' .  $return['output']);
  }
  return file_put_contents($filename, $return['output']);
}

/**
 * Command callback for the 'valkyrie-snapshot' command.
 */
function drush_valkyrie_db_diff() {
  $alias = drush_get_context('DRUSH_TARGET_SITE_ALIAS');
  if (drush_get_option('snapshot-file', FALSE)) {
    $snapshot = drush_get_option('snapshot-file');
  }
  else {
    $dir = drush_get_option('snapshot-dir', getcwd() . '/.valkyrie/cache/db-snapshots');
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
    if (!_drush_valkyrie_db_snapshot($alias, $filename)) {
      return FALSE;
    }
  }

  // Load our cached data
  $cached_diff_cmd = drush_cache_get('default_diff_cmd', 'valkyrie');
  if (!$cached_diff_cmd) {
    $default_diff_cmd = PHP_OS == 'Darwin' ? 'opendiff' : 'git diff --no-index -U0 --no-prefix';
    drush_cache_set('default_diff_cmd', $default_diff_cmd, 'valkyrie', DRUSH_CACHE_PERMANENT);
  }
  else {
    $default_diff_cmd = $cached_diff_cmd->data;
  }
  $diff_command = drush_get_option('diff-cmd', $default_diff_cmd);
  drush_shell_proc_open("$diff_command $snapshot $filename");
}

/**
 * Command callback for the 'valkyrie-logs' command.
 */
function drush_valkyrie_logs($log_path = '/var/log/apache2/error.log') {
  $server = _valkyrie_get_target_server_record();
  $command = "tail -f $log_path";
  _valkyrie_invoke_remote_cmd($server, $command);
}

/**
 * Command callback for the 'valkyrie-site-reinstall' command.
 */
function drush_valkyrie_site_reinstall() {
  $server = _valkyrie_get_target_server_record();
  $alias = $server['alias'];
  $command = "drush $alias provision-reinstall";
  _valkyrie_invoke_remote_cmd($server, $command);
}

/**
 * Command callback for the 'valkyrie-platform-generate' command.
 */
function drush_valkyrie_platform_generate($name) {
  $server = _valkyrie_get_target_server_record();

  $makefile_dir = getcwd() . '/.valkyrie/cache/makefiles';
  drush_mkdir($makefile_dir, FALSE);
  $makefile_path = $makefile_dir . "/$name.make";
  $lockfile_path = $makefile_dir . "/$name.lock";

  if ($makefile = drush_get_option('makefile', FALSE)) {
    if (is_readable($makefile)) {
      drush_log(dt('Caching makefile to: ' . $makefile_path));
      copy($makefile, $makefile_path);
    }
    else {
      drush_set_error('VALKYRIE_MISSING_MAKEFILE', dt('Cannot read a makefile at the specified path: ' . $makefile));
      return;
    }
  }
  else {
    // No makefile was specified, so we generate one from our template.
    $template = dirname(__FILE__) . '/templates/platform.make';
    $variables = array(
      'profile' => drush_get_option('profile', FALSE),
    );
    drush_log(dt('Generating makefile at: ' . $makefile_path));
    valkyrie_template($template, $makefile_path, $variables);
  }

  // Cache a lockfile from which to build the platform.
  $options = array(
    'lock' => $lockfile_path,
    'no-build' => 1,
  );
  drush_invoke_process('@none', 'make', array($makefile_path), $options);

  // Write an Aegir context for the new platform.
  $options = array(
    'context_type' => 'platform',
    'web_server' => '@server_master',
    'root' => "/var/aegir/platforms/$name",
    'makefile' => "/vagrant/.valkyrie/cache/makefiles/$name.lock",
  );
  drush_invoke_process('@self', 'provision-save', array("@platform_$name"), $options);

  if (drush_get_option('verify', FALSE)) {
    // Verify the new platform. This will run 'drush make'.
    $command = "drush @platform_$name provision-verify";
    _valkyrie_invoke_remote_cmd($server, $command);
  }

  // Copy the makefile and lockfile into the platform.
  drush_log(dt('Copying makefile and lockfile into platform drush directory.'));
  copy($makefile_path, getcwd() . "/platforms/$name/sites/all/drush/platform.make");
  copy($lockfile_path, getcwd() . "/platforms/$name/sites/all/drush/platform.lock");

  // Import the new platform context into the Hostmaster site.
  $command = "drush @hostmaster hosting-import @platform_$name";
  _valkyrie_invoke_remote_cmd($server, $command);

}

/**
 * Command callback for the 'valkyrie-platform-rebuild' command.
 */
function drush_valkyrie_platform_rebuild() {
  $arguments = array(
    d()->site_path . '/platform.make',
  );
  chdir(d()->platform->root);
  $options = array(
    'force-complete' => TRUE,
    'no-gitinfofile' => TRUE,
    'no-gitprojectinfo' => TRUE,
    'overwrite' => TRUE,
    'working-copy' => TRUE,
    'yes' => TRUE,
  );
  drush_invoke_process('@none','make', $arguments, $options);
}

/**
 * Command callback for the 'valkyrie-site-clone' command.
 */
function drush_valkyrie_site_clone($name, $git_repo) {
  $server = _valkyrie_get_target_server_record();

  // Cache a copy of the site git repo, so we can retrieve the makefile.
  // We do so from within the VM, to ensure the deploy key has been authorized
  // in the repo.
  $command = "git clone $git_repo /var/aegir/.cache/site_repos/$name";
  if ($branch = drush_get_option('branch', FALSE)) {
    $command .= " --branch=$branch";
    // Clear this option so that it doesn't interfere with later command
    // invocations.
    drush_unset_option('branch');
  }
  _valkyrie_invoke_remote_cmd($server, $command);

  // Retrieve the profile option then clear it so that it doesn't interfere
  // with later command invocations.
  $profile = drush_get_option('profile', 'minimal');
  drush_unset_option('profile');

  // Build a platform.
  $makefile = ".valkyrie/cache/site_repos/$name/platform.make";
  $platform_name = preg_replace("/[!\W\.\-]/", "", $name);
  drush_set_option('verify', TRUE);
  drush_invoke('valkyrie-platform-generate', array($platform_name, $makefile));
  drush_unset_option('verify');

  // Write an Aegir context for the new site.
  $options = array(
    'context_type' => 'site',
    'platform' => "@platform_$platform_name",
    'db_server' => '@server_localhost',
    'repo_url' => $git_repo,
    'deploy_from_git' => true,
    'git_ref' => isset($branch) ? $branch : 'master',
    'uri' => $name,
    'root' => "/var/aegir/platforms/$platform_name",
    'profile' => $profile,
    #'client_email' => 'me@example.com',
    # TODO: Why doesn't the above option work? Instead we need to do this in
    # drush_valkyrie_pre_provision_install_backend().
    # FWIW, passing --client_email to hosting-import doesn't work either.
  );
  drush_invoke_process('@self', 'provision-save', array("@$name"), $options);

  // TODO: Figure out a way to poll the Aegir queue for outstanding tasks.
  // Perhaps a hidden task we can run on the VM...
  drush_log('Waiting for platform to be ready.');
  _valkyrie_wait_for_queue();

  # enable $enable module or 'keystone' if it exists

  // Import the new site context into the Hostmaster site.
  $command = "drush @hostmaster hosting-import @$name";
  _valkyrie_invoke_remote_cmd($server, $command);

}

/**
 * Command callback for the 'valkyrie-site-generate' command.
 */
function drush_valkyrie_site_generate($name) {
  $server = _valkyrie_get_target_server_record();

  // Build a platform.
  $platform_name = preg_replace("/[!\W\.\-]/", "", $name);
  drush_set_option('verify', TRUE);
  drush_invoke('valkyrie-platform-generate', array($platform_name));
  drush_unset_option('verify');

  // Write an Aegir context for the new site.
  $options = array(
    'context_type' => 'site',
    'platform' => "@platform_$platform_name",
    'db_server' => '@server_localhost',
    // TODO: $git_repo will always be blank, at this point.
    'repo_url' => $git_repo,
    'deploy_from_git' => false,  # We're creating a new repo, not cloning an existing one.
    'git_ref' => 'master',
    'uri' => $name,
    'root' => "/var/aegir/platforms/$platform_name",
    'profile' => drush_get_option('profile', 'minimal'),
  );
  drush_invoke_process('@self', 'provision-save', array("@$name"), $options);

  // Install the new site.
  #$command = "drush @$name provision-install";
  #_valkyrie_invoke_remote_cmd($server, $command);
  drush_log('Waiting for platform to be ready.');
  _valkyrie_wait_for_queue();

  # copy gitignore into place
  # git init
  # git add .
  # git commit -m"Initial commit."
  # git push

  # provision_save set deploy_from_git true

  # TODO: add link to project url to frontend

  // Import the new site context into the Hostmaster site.
  $command = "drush @hostmaster hosting-import @$name";
  _valkyrie_invoke_remote_cmd($server, $command);

  drush_log('Waiting for site to be ready.');
  _valkyrie_wait_for_queue();

  drush_log(dt('Copying makefile into site directory.'));
  $sites_dir = getcwd() . "/platforms/$platform_name/sites";
  copy("$sites_dir/all/drush/platform.make", "$sites_dir/$name/platform.make");

}

/**
 * Load and validate a Valkyrie server alias record, or generate a default one.
 */
function _valkyrie_get_target_server_record($url = FALSE, $remote_user = 'aegir') {
  if ($url) {
    // We've been passed a URL, so we need to build our own alias.
    $server = array(
      'remote-host' => $url,
      'remote-user' => $remote_user,
    );
  }
  elseif (!$alias = drush_get_context('DRUSH_TARGET_SITE_ALIAS')) {
    drush_die(dt('A remote server alias is required. The way you call this Valkyrie command is: `drush @vm_alias valkyrie-cmd ... `.'));
  }
  else {
    $server = drush_sitealias_get_record($alias);
  }
  // We only accept remote aliases, since we run operations in a VM.
  if (empty($server['remote-host'])) {
    drush_die(dt('@alias does not specify a remote-host.', array('@alias' => $alias)));
  }
  return $server;
}

/**
 * Call a command on a Valkyrie server.
 */
function _valkyrie_invoke_remote_cmd($server, $command) {
  $cmd = drush_shell_proc_build($server, $command, NULL, FALSE);
  $status = drush_shell_proc_open($cmd);
  if ($status != 0) {
    return drush_set_error('DRUSH_SITE_SSH_ERROR', dt('An error @code occurred while running the command `@command`',
      array('@command' => $cmd, '@code' => $status)));
  }
  return $status;
}

/**
 * Implements drush_HOOK_pre_COMMAND().
 */
function drush_valkyrie_pre_user_login() {
  # Only operate on Valkyrie sites.
  $type = drush_get_option('valkyrie-type', FALSE);
  if ($type == 'site') {
    if ($login_uri = drush_get_option('login_uri', FALSE)) {
      # Alter the cached alias that will be re-dispatched to use our alternate
      # uri.
      $alias = &drush_get_context('alias');
      $alias['uri'] = $login_uri;
    }
  }
}

/**
 * Pause execution until the Aegir queue is no longer processing tasks.
 */
function _valkyrie_wait_for_queue() {
  while (_valkyrie_get_pending_task_count() > 0) {
    sleep(1);
  }
}

/**
 * Return the number of pending and processing tasks in the Aegir queue.
 */
function _valkyrie_get_pending_task_count() {
  $sql = "SELECT count(t.nid) FROM hosting_task t INNER JOIN node n ON t.vid = n.vid WHERE t.task_status = 0 OR task_status = -1";
  $server = _valkyrie_get_target_server_record(_valkyrie_get_aegir_vm_address());
  $result = drush_invoke_process($server, 'sql-query', array($sql), array(), FALSE);
  return $result['output'];
}

/**
 * Helper function to look up Aegir VM address.
 */
function _valkyrie_get_aegir_vm_address() {
  // TODO: as part of multi-vm/project support, figure out a way to look this
  // up.
  return 'valkyrie.local';
}
