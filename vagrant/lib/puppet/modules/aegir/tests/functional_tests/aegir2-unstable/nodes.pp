node "aegir2-unstable" {

  class { 'drush' :
    api  => 5,
  }

  class { 'aegir' :
    api     => 2,
    dist    => 'unstable',
    require => Class['drush'],
  }

}
