class avahi inherits aegir::defaults {

  # Install dependencies.
  package {['python-avahi', 'python-gobject', 'avahi-daemon']:
    ensure => present,
    before => Supervisor::Service['avahi-aliases'],
  }

  include supervisor
  supervisor::service { 'avahi-aliases':
    ensure  => 'running',
    user    => 'aegir',
    command => '/var/aegir/.drush/provision_avahi/publish.py --directory=/var/aegir/config/avahi-aliases',
  }

  # Install Provision extension.
  drush::git {'provision_avahi':
    path     => '/var/aegir/.drush/',
    git_repo => 'http://git.poeticsystems.com:valkyrie/provision_avahi.git',
    user     => 'aegir',
    require  => $aegir_installed,
  }

  # Allow 'aegir' user to restart the avahi-aliases daemon.
  file {'/etc/sudoers.d/aegir-avahi':
    source => 'puppet:///avahi/aegir-avahi.sudoers',
    mode   => '440',
    owner  => 'root',
    group  => 'root',
  }

}
