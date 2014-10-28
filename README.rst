Puppet module for configuring the 'supervisor' daemon control
utility. Currently tested on Debian, Ubuntu, and Fedora.

Install into `<module_path>/supervisor`

Example usage:

.. code-block:: puppet

  include supervisor

  supervisor::service {
    'scribe':
      ensure      => present,
      command     => '/usr/bin/scribed -c /etc/scribe/scribe.conf',
      environment => 'HADOOP_HOME=/usr/lib/hadoop,LD_LIBRARY_PATH=/usr/lib/jvm/java-6-sun/jre/lib/amd64/server',
      user        => 'scribe',
      group       => 'scribe',
      require     => [ Package['scribe'], User['scribe'] ];
  }

To use default debian paths:

.. code-block:: puppet

  class { 'supervisor':
    conf_dir => '/etc/supervisor/conf.d',
    conf_ext => '.conf',
  }

Running tests:

.. code-block:: sh

  $ bundle install --path=.gems
  $ bundle exec rake spec
