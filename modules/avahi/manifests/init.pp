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
  file {'/var/aegir/config/avahi-aliases':
    ensure  => directory,
    owner   => 'aegir',
    group   => 'aegir',
    require => $aegir_installed,
  }
  file {'/etc/avahi/aliases.d':
    ensure  => directory,
    require => Package['avahi-daemon'],
  }

  include supervisor
  supervisor::service { 'avahi-aliases':
    ensure  => 'running',
    command => '/var/aegir/.drush/provision_avahi/publish.py --directory=/var/aegir/config/avahi-aliases --debug',
    user    => 'aegir',
    require => Drush::Git['provision_avahi'],
  }

  # Allow 'aegir' user to restart the avahi-aliases daemon.
  file {'/etc/sudoers.d/aegir-avahi':
    source => 'puppet:///modules/avahi/aegir-avahi.sudoers',
    mode   => '440',
    owner  => 'root',
    group  => 'root',
  }

}
