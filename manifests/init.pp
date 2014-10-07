class avahi inherits aegir::defaults {

  # Install dependencies.
  package {['python-avahi', 'python-pip', 'avahi-daemon']:
    ensure  => present,
  }

  # Install daemon.
  exec { 'avahi pip':
    command => '/usr/bin/pip install git+git://github.com/PraxisLabs/avahi-aliases.git',
    require => Package['python-avahi', 'python-pip', 'avahi-daemon'],
  }

  # Install Provision extension.
  drush::git {'provision_avahi':
    path     => '/var/aegir/.drush/',
    git_repo => 'git://github.com/PraxisLabs/avahi-aliases.git',
    dir_name => 'provision_avahi',
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

  # Provide a file for aegir to register installed sites.
  file {'/var/aegir/config/avahi-aliases':
    ensure  => present,
    require => $aegir_installed,
    owner   => 'aegir',
    group   => 'aegir',
  }
  file {'/etc/avahi/aliases.d/aegir':
    target  => '/var/aegir/config/avahi-aliases',
    ensure  => link,
    require => File['/var/aegir/config/avahi-aliases'],
  }

}
