class aegir::apt ( $dist = 'stable' ) {

  $apt_keys_dir = '/root/apt_keys'

  if !defined(Package['debconf-utils']) {
    package { 'debconf-utils':
      ensure => present,
    }
  }

  file { 'aegir_apt_keys_dir':
    ensure => 'directory',
    path   => $apt_keys_dir,
    owner  => root, group => root, mode => '0755',
  }

  $apt_key_path = "${apt_keys_dir}/debian.aegirproject.org.key"

  file { 'aegir_apt_key':
    ensure  => present,
    path    => $apt_key_path,
    source  => 'puppet:///modules/aegir/debian.aegirproject.org.key',
    owner   => root, group => root, mode => '0644',
    require => File['aegir_apt_keys_dir'],
  }

  file {'aegir_apt_sources':
    ensure  => 'present',
    path    => "/etc/apt/sources.list.d/aegir-${dist}.list",
    content => "deb http://debian.aegirproject.org ${dist} main",
    owner   => root, group => root, mode => '0644',
    notify  => Exec['aegir_update_apt'],
    require => File['aegir_apt_key'],
  }

  exec { 'aegir_apt_key_add':
    command     => "apt-key add ${apt_key_path}",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    refreshonly => true,
    subscribe   => File['aegir_apt_key'],
    notify      => Exec['aegir_update_apt'],
  }

  exec { 'aegir_update_apt':
    command     => '/usr/bin/apt-get update',
    refreshonly => true,
    subscribe   => [
      File['aegir_apt_sources'],
      File['aegir_apt_key'],
    ],
    require     => Exec['aegir_apt_key_add'],
  }

  exec { 'aegir_apt_update':
    command  => '/usr/bin/apt-get update && /usr/bin/apt-get autoclean',
    require  => File['aegir_apt_sources'],
    schedule => daily,
  }

}
