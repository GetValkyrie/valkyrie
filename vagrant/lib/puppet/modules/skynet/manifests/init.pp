class skynet (
  $dependencies = true,
  $install      = true,
  $service      = true,
  $sudo         = true,
){

  if $dependencies {
    package {['python-pip', 'python-dev', 'build-essential', 'python-mysqldb']:
      ensure => present,
      before => Exec['upgrade pip'],
    }

    exec {'upgrade pip':
      command => 'pip install --upgrade pip',
      path    => ['/usr/local/bin', '/usr/bin'],
    }
    exec {'upgrade virtualenv':
      command => 'pip install --upgrade virtualenv',
      path    => ['/usr/local/bin', '/usr/bin'],
      require => Exec['upgrade pip'],
    }
    exec {'install cement':
      command => 'pip install cement',
      path    => ['/usr/local/bin', '/usr/bin'],
      require => Exec['upgrade virtualenv'],
    }
  }

  if $install {
    include drush::defaults
    drush::git {'https://github.com/PraxisLabs/skynet.git':
      path     => '/var/aegir/.drush',
      dir_name => 'skynet',
      user     => 'aegir',
    }
  }

  if $service {
    include supervisor
    supervisor::service { 'skynet-queue':
      ensure  => 'running',
      command => '/var/aegir/.drush/skynet/skynet.py queued --config_file=/var/aegir/config/skynet.conf',
      user    => 'aegir',
      environment => "HOME='/var/aegir',USER='aegir'",
    }
  }

  if $sudo {
    file {'/etc/sudoers.d/aegir-skynet-queue':
      content => "aegir ALL=(ALL)NOPASSWD:/usr/bin/supervisorctl start skynet-queue,/usr/bin/supervisorctl stop skynet-queue,/usr/bin/supervisorctl restart skynet-queue\n",
      mode    => '440',
      owner   => 'root',
      group   => 'root',
    }
  }

}
