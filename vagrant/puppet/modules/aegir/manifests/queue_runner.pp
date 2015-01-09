class aegir::queue_runner inherits aegir::defaults {

  drush::dl { 'hosting_queue_runner': }

  drush::en { 'hosting_queue_runner': }

  file {'hosting-queue-runner init script':
    ensure  => present,
    # ref.: http://drupalcode.org/project/hosting_queue_runner.git/blob_plain/refs/heads/6.x-1.x:/init.d.example
    source  => 'puppet:///modules/aegir/init.d.example',
    path    => '/etc/init.d/hosting-queue-runner',
    owner   => 'root', group => 'root', mode => '0755',
  }

  service {'hosting-queue-runner':
    ensure    => running,
    enable    => true,
    subscribe => File['hosting-queue-runner init script'],
    require   => Drush::En['hosting_queue_runner'],
  }

}
