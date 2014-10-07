class drush::apt::update {

  exec { 'drush_update_apt':
    command     => 'apt-get update & sleep 1',
    path        => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    refreshonly => true,
  }

  exec { 'drush_apt_update':
    command  => 'apt-get update && /usr/bin/apt-get autoclean',
    path     => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    schedule => daily,
  }

}
