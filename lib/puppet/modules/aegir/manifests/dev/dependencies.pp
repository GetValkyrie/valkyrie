class aegir::dev::dependencies {

  Package { ensure => present }

  if !defined(Package['php5'])       { package {'php5': } }
  if !defined(Package['php5-cli'])   { package {'php5-cli': } }
  if !defined(Package['php5-gd'])    { package {'php5-gd': } }
  if !defined(Package['php5-mysql']) { package {'php5-mysql': } }
  if !defined(Package['postfix'])    { package {'postfix': } }
  if !defined(Package['sudo'])       { package {'sudo': } }
  if !defined(Package['rsync'])      { package {'rsync': } }
  if !defined(Package['git'])        { package {'git': } }
  if !defined(Package['unzip'])      { package {'unzip': } }

}
