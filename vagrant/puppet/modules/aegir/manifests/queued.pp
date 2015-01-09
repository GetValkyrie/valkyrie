class aegir::queued inherits aegir::defaults {

  drush::en { 'hosting_queued': }

  file {'hosting-queued init script':
    ensure  => present,
    source  => 'puppet:///modules/aegir/init.d.example-new',
    path    => '/etc/init.d/hosting-queued',
    owner   => 'root', group => 'root', mode => '0755',
  }

  service {'hosting-queued':
    ensure    => running,
    enable    => true,
    subscribe => File['hosting-queued init script'],
    require   => Drush::En['hosting_queued'],
  }

}
