class aegir::mysql ($secure = TRUE) {

  include aegir::mysql::preseed

  package {'mysql-server': ensure => present,}

  service {'mysql':
    ensure  => running,
    require => Package['mysql-server'],
  }

  if $secure {
    # Equivalent to /usr/bin/mysql_secure_installation without providing or setting a password
    # From: http://matthewturland.com/2012/02/13/setting-up-ec2-for-drupal-with-puppet/
    exec { 'mysql_secure_installation':
      command   => '/usr/bin/mysql -uroot -e "DELETE FROM mysql.user WHERE User=\'\'; DELETE FROM mysql.user WHERE User=\'root\' AND Host NOT IN (\'localhost\', \'127.0.0.1\', \'::1\'); DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;" mysql',
      subscribe => Package['mysql-server'],
      require   => Exec['change mysql root password'],
    }

    file {'/root/.my.cnf':
      content => template('aegir/my_cnf.erb'),
      mode    => 0600,
      replace => false,
      notify  => Exec['change mysql root password'],
    }

    ## See: https://labs.riseup.net/code/projects/shared-mysql/repository/revisions/master/entry/manifests/server/base.pp#L42
    file { 'setmysqlpass.sh':
      path => '/usr/local/sbin/setmysqlpass.sh',
      source => "puppet:///modules/aegir/scripts/setmysqlpass.sh",
      require => Package['mysql-server'],
      owner => root, group => 0, mode => 0500;
    }

    exec {'change mysql root password':
      command => '/usr/local/sbin/setmysqlpass.sh',
      unless => '/usr/bin/mysqladmin -uroot status > /dev/null',
      require => [ File['setmysqlpass.sh'], Package['mysql-server'] ],
      refreshonly => true,
      before      => Exec['preseed mysql password'],
    }
  }

}
