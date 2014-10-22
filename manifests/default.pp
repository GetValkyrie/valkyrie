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
  file {'/vagrant/.first_run_complete':
    ensure  => present,
    require => File["$aegir_root/.ssh/authorized_keys"],
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

  drush::en {['hosting_git', 'hosting_platform_pathauto', 'hosting_git_pull']:
    site_alias => '@hm',
    drush_home => $aegir_root,
    require    => Class['aegir::dev'],
  }

  include valkyrie::deploy_keys

  #drush::git {'http://git.poeticsystems.com/valkyrie/drush-valkyrie.git':
  drush::git {'git@git.poeticsystems.com:valkyrie/drush-valkyrie.git':
    path     => '/var/aegir/.drush',
    dir_name => 'valkyrie',
    user     => $aegir_user,
    require => User[$aegir_user],
  }

  drush::run {"drush-cc-drush:valkyrie":
    command     => 'cache-clear drush',
    drush_user  => $drush_user,
    drush_home  => $drush_home,
    refreshonly => true,
    subscribe   => Drush::Git['git@git.poeticsystems.com:valkyrie/drush-valkyrie.git'],
  }

}
