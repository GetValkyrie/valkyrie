node default {

  package { ['vim', 'htop', 'screen', 'tree']:
    ensure => present
  }

  class {'drush::git::drush':
    git_branch => '6.x',
    #git_branch => 'master',
    before     => Class['aegir::dev'],
  }

  class { 'aegir::dev' :
    hostmaster_ref  => '7.x-3.x',
    provision_ref   => '7.x-3.x',
    make_aegir_platform  => true,
    makefile        => '/var/aegir/.drush/provision/aegir-dev.make',
    platform_path   => '/var/aegir/hostmaster-7.x-3.x',
  }

}
