node "aegir3-dev.test" {

  class { 'drush::git::drush' :
    git_branch => '6.x',
    #git_tag    => '6.2.0',
  }

  class { 'aegir::dev' :
    hostmaster_ref => '7.x-3.x',
    provision_ref  => '7.x-3.x',
    platform_path  => '/var/aegir/hostmaster-7.x-3.x',
    require        => Class['drush::git::drush'],
  }

}
