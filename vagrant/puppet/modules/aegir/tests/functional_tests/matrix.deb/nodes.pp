node "aegir.test" {

  class { 'drush' :
    api  => $drush_api,
  }

  class { 'aegir' :
    api        => $aegir_api,
    dist       => $aegir_dist,
    web_server => $aegir_web_server,
    require    => Class['drush'],
  }

}
