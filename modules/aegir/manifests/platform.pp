define aegir::platform ( $makefile ) {

  include aegir::defaults

  drush::run {"provision-save:${name}":
    command   => 'provision-save',
    arguments => "@platform_${name}",
    options   => "--root=${aegir::defaults::aegir_root}/platforms/${name} --context_type='platform' --makefile='${makefile}'",
    creates   => "${aegir::defaults::aegir_root}/.drush/platform_${name}.alias.drushrc.php",
    require   => $aegir::defaults::aegir_installed,
    notify    => Drush::Run["hosting-import:${name}"],
  }

  drush::run {"hosting-import:${name}":
    command     => 'hosting-import',
    arguments   => "@platform_${name}",
    refreshonly => true,
  }

}
