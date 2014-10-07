class aegir::remote_import (
  $aegir_version = '6.x-1.x'
  ) inherits aegir::defaults {

/*
  # Pending http://drupal.org/node/1662822
  drush::dl { 'remote_import':
    site_alias => false,
    site_path  => "${aegir_root}/.drush/provision/",
    require    => $aegir::defaults::egir_installed,
  }
*/

  drush::git { 'http://git.drupal.org/sandbox/ergonlogic/1681684.git':
    # Here we're using a sandbox that has a patch applied.
    # Ref. http://drupal.org/node/1663066.
    git_branch => '1663066',
    dir_name   => 'remote_import',
    path       => '/usr/share/drush/commands/provision/',
    require    => $aegir::defaults::aegir_installed,
  }

/*
  # Pending http://drupal.org/node/1662820
  drush::dl { 'hosting_remote_import':
    site_alias => '@hostmaster',
    site_path  => "${aegir::defaults::aegir_root}/hostmaster-${aegir_version}/sites/${aegir::defaults::frontend_url}",
    require    => Drush::Dl['remote_import'],
  }
*/
  drush::git { 'http://git.drupal.org/project/hosting_remote_import.git':
    git_branch => '6.x-1.x',
    path       => "${aegir::defaults::aegir_root}/hostmaster-${aegir_version}/sites/${aegir::defaults::frontend_url}/modules",
    require    => $aegir::defaults::aegir_installed,
    notify     => Drush::En['hosting_remote_import'],
  }

  drush::en { 'hosting_remote_import':
    site_alias => '@hostmaster',
  }

  # TODO: ssh key share for aegir user
  # TODO: fix http://drupal.org/node/1663066
}
