node default {

  package { ['vim', 'htop', 'screen', 'tree']:
    ensure => present
  }

  $aegir_user = 'aegir'
  $aegir_root = '/var/aegir'
  $web_group  = 'www-data'

  User <| title == $aegir_user |> {
    groups  => [$web_group, 'admin'], #Allow password-less sudo
    shell   => '/bin/bash',
  }

  if $first_run {
    file {"$aegir_root/.ssh":
      ensure  => directory,
      owner   => $aegir_user,
      group   => $aegir_user,
      require => User[$aegir_user],
    }
    file {"$aegir_root/.ssh/authorized_keys":
      ensure  => present,
      source  => '/vagrant/authorized_keys',
      mode    => 600,
      owner   => $aegir_user,
      group   => $aegir_user,
      require => File["$aegir_root/.ssh"],
    }
    file {'/vagrant/.first_run':
      ensure  => present,
      require => File["$aegir_root/.ssh/authorized_keys"],
    }
  }

  class {'drush::git::drush':
    #git_branch => '6.x',
    git_branch => 'master',
    before     => Class['aegir::dev'],
  }

  class { 'aegir::dev' :
    hostmaster_ref  => '7.x-3.x',
    provision_ref   => '7.x-3.x',
    make_aegir_platform  => true,
    makefile        => '/var/aegir/.drush/provision/aegir-dev.make',
    platform_path   => '/var/aegir/hostmaster-7.x-3.x',
  }

  include avahi

  drush::en {['hosting_git', 'hosting_platform_pathauto']:
    site_alias => '@hm',
    drush_home => $aegir_root,
  }

  include valkyrie::deploy_keys

#  drush::git {'http://git.poeticsystems.com/camden/valkyrie.git':
#    path => '/var/aegir/.drush/valkyrie',
#    user => $aegir_user,
#  }

}
