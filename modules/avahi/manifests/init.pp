class avahi inherits aegir::defaults {

  # Install dependencies.
  package {['python-avahi', 'python-gobject', 'avahi-daemon']:
    ensure => present,
    before => Supervisor::Service['avahi-aliases'],
  }

  # Install Provision extension.
  drush::git {'provision_avahi':
    path     => '/var/aegir/.drush/',
    git_repo => 'git@git.poeticsystems.com:valkyrie/provision_avahi.git',
    user     => 'aegir',
    require  => $aegir_installed,
  }

  file {'/etc/avahi/aliases.d':
    ensure => directory,
  }

  include supervisor
  supervisor::service { 'avahi-aliases':
    ensure  => 'running',
    command => '/var/aegir/.drush/provision_avahi/publish.py --directory=/var/aegir/config/avahi-aliases',
    require => Drush::Git['provision_avahi'],
  }

  # Allow 'aegir' user to restart the avahi-aliases daemon.
  file {'/etc/sudoers.d/aegir-avahi':
    source => 'puppet:///avahi/aegir-avahi.sudoers',
    mode   => '440',
    owner  => 'root',
    group  => 'root',
  }

}
