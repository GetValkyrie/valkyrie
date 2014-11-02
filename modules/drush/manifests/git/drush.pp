class drush::git::drush (
  $git_branch = '',
  $git_tag    = '',
  $git_repo   = 'https://github.com/drush-ops/drush.git',
  $update     = false
  ) inherits drush::defaults {

  include drush::apt::update

  Exec { path    => ['/bin', '/usr/bin', '/usr/local/bin', '/usr/share'], }

  if !defined(Package['git']) and !defined(Package['git-core']) {
    package { 'git':
      ensure => present,
      require => Exec['drush_update_apt'],
    }
  }

  if !defined(Package['php5-cli']) {
    package { 'php5-cli':
      ensure => present,
      require => Exec['drush_update_apt'],
    }
  }

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present,
      require => Exec['drush_update_apt'],
    }
  }

  drush::git { $git_repo :
    path       => '/usr/share',
    git_branch => $git_branch,
    git_tag    => $git_tag,
    update     => $update,
    require    => Package['git'],
  }

  file {'symlink drush':
    ensure  => link,
    path    => '/usr/bin/drush',
    target  => '/usr/share/drush/drush',
    require => Drush::Git[$git_repo],
    notify  => Exec['first drush run'],
  }

  exec {'Install composer' :
    command => 'curl -sS https://getcomposer.org/installer | php',
    cwd     => '/usr/share/drush',
    creates => '/usr/share/drush/composer.phar',
    notify  => Exec['Install Drush dependencies'],
    require => Package['php5-cli', 'curl'],
  }

  exec {'Install Drush dependencies' :
    command     => 'php ./composer.phar install > composer.log',
    environment => ["COMPOSER_HOME=/usr/share/drush"],
    cwd         => '/usr/share/drush',
    refreshonly => true,
    require     => Exec['Install composer'],
  }

  # Needed to download a Pear library
  exec {'first drush run':
    command     => 'drush cache-clear drush',
    refreshonly => true,
    require     => [
      File['symlink drush'],
      Package['php5-cli'],
      Exec['Install Drush dependencies'],
    ],
  }

}
