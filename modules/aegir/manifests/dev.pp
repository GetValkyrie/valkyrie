class aegir::dev (
  $frontend_url = $fqdn,
  $db_host      = $aegir::defaults::db_host,
  $db_port      = $aegir::defaults::db_port,
  $db_user      = $aegir::defaults::db_user,
  $db_password  = $aegir::defaults::db_password,
  $admin_email  = $aegir::defaults::admin_email,
  $admin_name   = $aegir::defaults::admin_name,
  $makefile     = $aegir::defaults::makefile,
  $aegir_user   = $aegir::defaults::aegir_user,
  $aegir_root   = $aegir::defaults::aegir_root,
  $web_group    = $aegir::defaults::web_group,
  $db_server    = $aegir::defaults::db_server,
  $web_server   = $aegir::defaults::web_server,
  $web_port     = $aegir::defaults::web_port,
  $update       = false,
  $platform_path      = false,
  $drush_make_version = false,
  $make_aegir_platform  = false,
  $hostmaster_repo    = 'http://git.drupal.org/project/hostmaster.git',
  $hostmaster_ref     = '7.x-3.x',
  $provision_repo     = 'http://git.drupal.org/project/provision.git',
  $provision_ref      = '7.x-3.x',
  $provision_git_repo     = 'http://git.drupal.org/project/provision_git.git',
  $provision_git_ref      = '7.x-3.x',
  $install_dependencies = true
  ) inherits aegir::defaults {

  # Ref.: http://community.aegirproject.org/installing/manual#Create_the_Aegir_user
  group {$aegir_user:
    ensure => present,
    system => true,
  }

  user {$aegir_user:
    ensure  => present,
    system  => true,
    gid     => $aegir_user,
    home    => $aegir_root,
    groups  => $web_group,
    require => Group[$aegir_user],
  }

  file { [ $aegir_root, "${aegir_root}/.drush" ]:
    ensure  => directory,
    owner   => $aegir_user,
    group   => $aegir_user,
    require => User[$aegir_user],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_provision
  drush::git { 'Install provision':
    git_repo   => $provision_repo,
    git_branch => $provision_ref,
    dir_name   => 'provision',
    path       => "${aegir_root}/.drush/",
    require    => File[ $aegir_root, "${aegir_root}/.drush"],
    update     => $update,
  }

  file {"${aegir_root}/.drush/provision":
    ensure   => present,
    owner    => 'aegir',
    group    => 'aegir',
    loglevel => 'debug',
    recurse  => true,
    require  => Drush::Git['Install provision'],
    before   => Drush::Run['hostmaster-install'],
  }

  drush::git { 'Install provision_git':
    git_repo   => $provision_git_repo,
    git_branch => $provision_git_ref,
    dir_name   => 'provision_git',
    path       => "${aegir_root}/.drush/",
    require    => File[ $aegir_root, "${aegir_root}/.drush", "${aegir_root}/.drush/provision"],
    update     => $update,
  }

  file {"${aegir_root}/.drush/provision_git":
    ensure   => present,
    owner    => 'aegir',
    group    => 'aegir',
    loglevel => 'debug',
    recurse  => true,
    require  => Drush::Git['Install provision_git'],
    before   => Drush::Run['hostmaster-install'],
  }

  drush::run { 'cache-clear drush':
    site_alias => '@none',
    require    => File["${aegir_root}/.drush/provision"],
    before     => Drush::Run['hostmaster-install'],
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Install_system_requirements
  exec { 'aegir_dev_update_apt':
    command     => '/usr/bin/apt-get update && sleep 1',
  }

  if $install_dependencies != false {

    class { 'aegir::dev::dependencies':
      require => Exec['aegir_dev_update_apt'],
      before  => Drush::Run['hostmaster-install'],
    }

    include drush::git::drush

    if $web_server != false {

      package { $web_server :
        ensure  => present,
        require => Exec['aegir_dev_update_apt'],
        before  => [
          User[$aegir_user],
          Drush::Run['hostmaster-install'],
        ],
      }
    }

    if $db_server != false {

      # Ref.: http://community.aegirproject.org/installing/manual#Database_configuration
      case $db_server {
        'mysql': {
          package {'mysql-server':
            ensure  => present,
            require => Exec['aegir_dev_update_apt'],
            before  => Drush::Run['hostmaster-install'],
          }
          # Equivalent to /usr/bin/mysql_secure_installation without providing or setting a password
          # From: http://matthewturland.com/2012/02/13/setting-up-ec2-for-drupal-with-puppet/
          exec { 'mysql_secure_installation':
            command => '/usr/bin/mysql -uroot -e "DELETE FROM mysql.user WHERE User=\'\'; DELETE FROM mysql.user WHERE User=\'root\' AND Host NOT IN (\'localhost\', \'127.0.0.1\', \'::1\'); DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;" mysql',
            subscribe   => Package['mysql-server'],
            before      => Drush::Run['hostmaster-install'],
          }
        }
        #'mariadb': { /* To do */ }
        #'postgresql': { /* To do */ }
        default: {
          err("'${db_server}' is not a supported database server. Supported database servers include 'mysql'.")
        }
      }
    }
  }

  case $web_server {
    # Ref.: http://community.aegirproject.org/installing/manual#Nginx_configuration
    'nginx': {
      $http_service_type = 'nginx'
      package { 'php5-fpm':
        ensure => present,
        require => Exec['aegir_dev_update_apt'],
        before => File['/etc/nginx/conf.d/aegir.conf'],
      }
      file { '/etc/nginx/conf.d/aegir.conf' :
        ensure  => link,
        target  => "${aegir_root}/config/nginx.conf",
        require => Package[$web_server],
        before  => Drush::Run['hostmaster-install'],
      }
    }
    # Ref.: http://community.aegirproject.org/installing/manual#Apache_configuration
    'apache2': {
      $http_service_type = 'apache'
      exec { 'Enable mod-rewrite' :
        command     => 'a2enmod rewrite',
        unless      => 'apache2ctl -M | grep rewrite',
        refreshonly => true,
        path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
        require     => Package[$web_server],
        before      => Drush::Run['hostmaster-install'],
      }
      file { '/etc/apache2/conf.d/aegir.conf':
        ensure  => link,
        target  => "${aegir_root}/config/apache.conf",
        notify  => Exec['Enable mod-rewrite'],
        require => Package[$web_server],
        before  => Drush::Run['hostmaster-install'],
      }
    }
    default: {
      err("'${web_server}' is not a supported web server. Supported web servers include 'apache2' or 'nginx'.")
    }
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#PHP_configuration

  # Ref.: http://community.aegirproject.org/installing/manual#Sudo_configuration
  file {'/etc/sudoers.d/aegir':
    ensure  => present,
    content => "aegir ALL=NOPASSWD: /usr/sbin/apache2ctl\naegir ALL=NOPASSWD: /etc/init.d/nginx\n",
    mode    => '0440',
    before  => Drush::Run['hostmaster-install'],
  }

  # Note: skipping http://community.aegirproject.org/installing/manual#DNS_configuration

  # Note: Skipping the below (for now)
  # comment out 'bind-address = 127.0.0.1' from /etc/mysql/my.cnf
  # exec /etc/init.d/mysql restart

  if $make_aegir_platform != false and $makefile != false {
    drush::run {'cc drush':
      site_alias => '@none',
      drush_user => $aegir_user,
      drush_home => $aegir_root,
      require    => Drush::Git['Install provision'],
    }
    # Run Drush Make ourselves, since some options won't filter down through hostmaster-install.
    drush::make { 'Build Hostmaster platform':
      makefile   => $makefile,
      make_path  => $platform_path,
      options    => ' --working-copy --no-gitinfofile',
      drush_user => $aegir_user,
      drush_home => $aegir_root,
      log        => "${aegir_root}/hostmaster_make.log",
      before     => Drush::Run['hostmaster-install'],
      require    => Drush::Run['cc drush'],
    }
  }

  # Ref.: http://community.aegirproject.org/installing/manual#Running_hostmaster-install

  # Build our options
  $default_options = " --debug --working-copy --aegir_version=${hostmaster_ref} --strict=0"
  if $aegir_user {        $a = " --script_user=${aegir_user}" }
  if $aegir_root {        $b = " --aegir_root=${aegir_root}" }
  if $web_group {         $c = " --web_group=${web_group}" }
  if $db_host {           $d = " --aegir_db_host=${db_host}" }
  if $db_port {           $e = " --aegir_db_port=${db_port}" }
  if $db_user {           $f = " --aegir_db_user${db_user}" }
  if $db_password {       $g = " --aegir_db_pass=${db_password}" }
  if $http_service_type { $h = " --http_service_type=${http_service_type}"}
  if $drush_make_version{ $i = " --drush_make_version=${drush_make_version}"}
  if $admin_email {       $j = " --client_email=${admin_email}"}
  if $admin_name {        $k = " --client_name=${admin_name}"}
  if $makefile {          $l = " --makefile=${makefile}"}
  if $frontend_url {      $m = " --aegir_host=${frontend_url}"}
  if $web_port {          $n = " --http_port=${web_port}"}
  if $platform_path {     $o = " --root=${platform_path}" }
  $install_options = "$default_options${a}${b}${c}${d}${e}${f}${g}${h}${i}${j}${k}${l}${m}${n}${o}"

  drush::run {'hostmaster-install':
    site_alias => '@none',
    arguments  => $frontend_url,
    options    => $install_options,
    log        => '/var/aegir/install.log',
    creates    => "${aegir_root}/hostmaster-${hostmaster_ref}/sites/$frontend_url",
    drush_user => $aegir_user,
    drush_home => $aegir_root,
    require    => User[$aegir_user],
    timeout    => 0,
  }

  file { 'queue daemon init script':
    source  => 'puppet:///modules/aegir/init.d.example-new',
    path    => '/etc/init.d/hosting-queued',
    owner   => 'root',
    mode    => 0755,
    require => Drush::Run['hostmaster-install'],
  }
  drush::en { 'hosting_queued':
    refreshonly => true,
    subscribe   => File['queue daemon init script'],
    before      => Service['hosting-queued'],
  }
  service { 'hosting-queued':
    ensure  => running,
    subscribe => File['queue daemon init script'],
  }

  exec {'aegir-dev login':
    command     => "\
echo '*******************************************************************************'\n
echo '* Open the link below to access your new Aegir site:'\n
echo '*' `env HOME=${aegir_root} drush @hostmaster uli`\n
echo '*******************************************************************************'\n
",
    loglevel    => 'alert',
    logoutput   => true,
    user        => $aegir_user,
    environment => "HOME=${aegir_root}",
    path        => ['/bin', '/usr/bin'],
    require     => Drush::Run['hostmaster-install'],
  }

  if $update {
    $provision_dir     = "${aegir_root}/.drush/provision"
    $provision_git_dir = "${aegir_root}/.drush/provision_git"
    $hostmaster_dir    = "${aegir_root}/hostmaster-${hostmaster_ref}/profiles/hostmaster"
    $hosting_dir       = "${hostmaster_dir}/modules/hosting"
    $hosting_git_dir   = "${hostmaster_dir}/modules/hosting_git"
    $eldir_dir         = "${hostmaster_dir}/themes/eldir"
    exec { 'update provision':
      command => "cd ${provision_dir} && git pull -r",
    }
    exec { 'update provision_git':
      command => "cd ${provision_git_dir} && git pull -r",
    }
    exec { 'update hostmaster':
      command => "cd ${hostmaster_dir} && git pull -r",
    }
    exec { 'update hosting':
      command => "cd ${hosting_dir} && git pull -r",
    }
    exec { 'update hosting_git':
      command => "cd ${hosting_git_dir} && git pull -r",
    }
    exec { 'update eldir':
      command => "cd ${eldir_dir} && git pull -r",
    }
    drush::run {'update_db':
      site_alias => '@hostmaster',
      require    => [
        Exec['update hostmaster'],
        Exec['update hosting'],
        Exec['update eldir'],
      ],
    }
  }

}
