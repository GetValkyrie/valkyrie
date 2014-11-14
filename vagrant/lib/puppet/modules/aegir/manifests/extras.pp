class aegir::extras inherits aegir::defaults {

  Drush::Dl { require => $aegir::defaults::aegir_installed }

  drush::dl { 'registry_rebuild':
    options => '--default-major=7',
    type => 'extension',
  }

  drush::dl { 'provision_tasks_extra':
    options => '--default-major=6',
    type => 'extension',
  }

  drush::dl { 'hosting_tasks_extra':
    require => [ Drush::Dl['registry_rebuild'], Drush::Dl['provision_tasks_extra'] ],
  }

  drush::en { 'hosting_tasks_extra':
    require => Drush::Dl['hosting_tasks_extra'],
  }
}
