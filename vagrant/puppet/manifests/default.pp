node default {

  $aegir_user = 'aegir'
  $aegir_root = '/var/aegir'

  if $first_run == 'True' {
    user {$aegir_user :
      shell => '/bin/bash',
      home  => $aegir_root,
    }
    # Allow 'aegir' user password-less sudo.
    file {'/etc/sudoers.d/aegir-sudo':
      content => "${aegir_user} ALL=NOPASSWD:ALL",
      mode    => '440',
      owner   => 'root',
      group   => 'root',
    }
    file {$aegir_root :
      ensure  => directory,
      owner   => $aegir_user,
      group   => $aegir_user,
      require => User[$aegir_user],
    }
    file {"$aegir_root/.ssh":
      ensure  => directory,
      owner   => $aegir_user,
      group   => $aegir_user,
      require => File[$aegir_root],
    }
    file {"$aegir_root/.ssh/authorized_keys":
      ensure  => present,
      source  => '/vagrant/.valkyrie/ssh/authorized_keys',
      mode    => 600,
      owner   => $aegir_user,
      group   => $aegir_user,
      require => File["$aegir_root/.ssh"],
    }
    file {'/home/ubuntu/.ssh/authorized_keys':
      ensure  => present,
      source  => '/vagrant/.valkyrie/ssh/authorized_keys',
      mode    => 600,
      owner   => 'ubuntu',
      group   => 'ubuntu',
    }
    file {'/vagrant/.valkyrie/cache':
      ensure => directory,
    }
    file {'/vagrant/.valkyrie/cache/first_run_complete':
      ensure  => present,
      content => generate('/bin/date', '+%Y%d%m_%H:%M:%S'),
      require => [
        File["$aegir_root/.ssh/authorized_keys"],
        File['/vagrant/.valkyrie/cache'],
        File['/home/ubuntu/.ssh/authorized_keys'],
      ]
    }

  }
  else {

    package { ['vim', 'htop', 'screen', 'tree']:
      ensure => present
    }

    $web_group  = 'www-data'

    $alt_id = 1010
    case $host_os {
      'darwin': {
        # Move the 'dialout' group out of the way on OSX hosts.
        group { "dialout":
          gid    => $alt_id,
          before => [
            Group[$web_group],
            Exec["Make files owned by web-user map to host user's gid"],
          ]
        }
        exec { "/usr/bin/find / -group ${host_gid} -not -path \"/proc/*\" -exec chgrp -h $alt_id {} ';'":
          subscribe => Group['dialout'],
          before    => [
            Group[$web_group],
            Exec["Make files owned by web-user map to host user's gid"],
          ]
        }
      }
      /linux/, default: {
        # Move the 'vagrant' user and group out of the way on GNU/Linux hosts.
        group {'vagrant':
          gid => $alt_id,
        }
        user {'vagrant':
          uid    => $alt_id,
          gid    => $alt_id,
          before => [
            Group[$web_group],
            User[$aegir_user],
            Exec["Make files owned by web-user map to host user's gid"],
          ],
          require => Group['vagrant'],
        }
      }
    }

    group { $web_group:
      gid => $host_gid,
    }

    exec { "Make files owned by web-user map to host user's gid" :
      command   => "/usr/bin/find / -group 33 -not -path \"/proc/*\" -exec chgrp -h ${host_gid} {} ';'",
      refreshonly => true,
      subscribe => Group[$web_group],
    }

    User <| title == $aegir_user |> {
      uid     => $host_uid,
      groups  +> [$web_group, 'adm'], #Allow access to logs
      require => Group[$web_group],
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
      queued_service  => false,
    }

    if $domain == 'local' {
      include avahi
    }
    include skynet

    # Ensure our git code is running on our dev branch
    #drush::git {'ergonlogic@git.drupal.org:project/hosting_git.git':
    drush::git {'http://git.drupal.org/project/hosting_git.git':
      path       => '/var/aegir/hostmaster-7.x-3.x/profiles/hostmaster/modules/aegir',
      dir_name   => 'hosting_git',
      git_branch => 'dev/2362437',
      user       => $aegir_user,
      #update     => true,
      require    => Class['aegir::dev'],
      before     => Drush::En['hosting_alias'],
    }
    drush::git {'http://git.drupal.org/sandbox/ergonlogic/2386543.git':
      path       => '/var/aegir/hostmaster-7.x-3.x/profiles/hostmaster/modules/aegir',
      dir_name   => 'hosting_reinstall',
      git_branch => '7.x-3.x',
      user       => $aegir_user,
      #update     => true,
      require    => Class['aegir::dev'],
      before     => Drush::En['hosting_alias'],
    }
    /*
    drush::git {'http://git.poeticsystems.com/valkyrie/hosting-storage.git':
      path       => '/var/aegir/hostmaster-7.x-3.x/profiles/hostmaster/modules/aegir',
      dir_name   => 'hosting_storage',
      git_branch => '7.x-3.x',
      #git_branch => 'master',
      user       => $aegir_user,
      #update     => true,
      require    => Class['aegir::dev'],
      before     => Drush::En['hosting_alias'],
    }
    */

    $valkyrie_modules = 'hosting_alias hosting_git hosting_git_pull hosting_platform_pathauto hosting_reinstall'
    #'hosting_storage',  # Not ready for default usage.
    drush::en { 'hosting_alias':
      # Here we trick Puppet into enabling all our modules at once, to avoid
      # running a 'verify' task for each one. We name this resource after one of
      # them, so that Drush::En's 'unless' clause doesn't block its running.
      arguments  => $valkyrie_modules,
      site_alias => '@hm',
      drush_user => $aegir_user,
      drush_home => $aegir_root,
      require    => [
        Class['aegir::dev'],
        Drush::Run['drush-cc-drush:valkyrie'],
      ]
    }

    include valkyrie::deploy_keys

    drush::run {"drush-cc-drush:valkyrie":
      command     => 'cache-clear drush',
      drush_user  => $aegir_user,
      drush_home  => '/var/aegir',
      refreshonly => true,
    }

    # Set a default URL alias (based on the Facter-provided $domain)
    drush::run {'drush-vset-tld':
      command    => "vset hosting_alias_subdomain ${domain}",
      site_alias => '@hm',
      drush_user => $aegir_user,
      drush_home => '/var/aegir',
      unless     => "/usr/bin/drush @hm vget hosting_alias_subdomain|/bin/grep ${domain}",
      require    => Class['aegir::dev'],
    }

    # Allow site deletion without disabling first.
    drush::run {'drush-vset-no-disable-before-delete':
      command    => "vset hosting_require_disable_before_delete 0",
      site_alias => '@hm',
      drush_user => $aegir_user,
      drush_home => '/var/aegir',
      unless     => "/usr/bin/drush @hm vget hosting_require_disable_before_delete|/bin/grep 0",
      require    => Class['aegir::dev'],
    }

  }

}
