define aegir::platform::build (
  $makefile,
  $force_complete = false,
  $working_copy   = false,
  ) {

  include aegir::defaults

  if $force_complete { $force_opt = ' --force-complete' }
  if $working_copy { $working_opt = ' --working-copy' }

  # we need to run drush make (and not verify) in order to override
  # the drush make settings, because provision-verify won't take the
  # --working-copy or --force-complete settings and pass them to
  # drush make. hosting-import (below) will make the frontend run
  # provision-verify through the queue eventually anyways.

  drush::make {"${aegir::defaults::aegir_root}/platforms/${name}":
    makefile => $makefile,
    options  => "${force_opt} ${working_opt}",
    require  => $aegir::defaults::aegir_installed,
    notify   => Drush::Run["provision-save:${name}"],
  }

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
