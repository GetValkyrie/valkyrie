class valkyrie::deploy_keys (
  $ssh_user       = 'aegir',
  $comment        = 'Valkyrie deploy key',
  $key_dir        = '/var/aegir/.ssh',
  $host_key_dir   = '/vagrant/.valkyrie/ssh',
  $key_name       = 'id_rsa',
  $ssh_host_alias = 'gitlab',
  $ssh_hostname   = 'git.poeticsystems.com'){

  # All files should default to the ssh user
  File { owner => $ssh_user, group => $ssh_user }
  # For debugging
  Exec { logoutput => on_failure, path => ["/bin", "/usr/bin", "/usr/sbin"] }

  if !defined(File[$key_dir]) {
    file { $key_dir :
      ensure => directory,
    }
  }

  # Generate an SSH key-pair
  exec { "Generate '${key_name}' keypair" :
    command => "ssh-keygen -t rsa -N '' -C '${comment}' -f ${key_dir}/${key_name}",
    creates => ["${key_dir}/${key_name}", "${key_dir}/${key_name}.pub"],
    require => File[$key_dir],
  }
  # SSH private keys have to be secured
  file { "Secure '${key_name}' private key" :
    path    => "${key_dir}/${key_name}",
    ensure  => file,
    mode    => '0600',
    require => Exec["Generate '${key_name}' keypair"],
  }
  file {"${key_dir}/config":
    ensure   => file,
    content => "StrictHostKeyChecking no
UserKnownHostsFile=/dev/null

Host ${ssh_host_alias}
        Hostname ${ssh_hostname}
        IdentityFile ${key_dir}/${key_name}",
    require => File[$key_dir],
  }

  # Use existing keys, if they exist.
  file { 'Restore keys script' :
    content => "if [ -e ${host_key_dir}/\$1 ]; then /bin/cp ${host_key_dir}/\$1* . ; fi",
    path    => '/usr/local/sbin/restore_ssh_keys.sh',
    mode    => 755,
  }
  exec { "Use existing ${key_name} keys":
    command => "/usr/local/sbin/restore_ssh_keys.sh ${key_name}",
    cwd     => $key_dir,
    provider => 'shell',
    creates => ["${key_dir}/${key_name}", "${key_dir}/${key_name}.pub"],
    before  => Exec["Generate '${key_name}' keypair"],
    require => [
      File[$key_dir],
      File['Restore keys script'],
    ],
  }

  # Store backups of keys.
  file { $host_key_dir:
    ensure => directory,
    #owner  => 'vagrant',
    #group  => 'vagrant',
  }

  file { 'Backup keys script' :
    content => "if ! [ -e ${host_key_dir}/\$1 ]; then /bin/cp ./\$1* ${host_key_dir}/; fi",
    path    => '/usr/local/sbin/backup_ssh_keys.sh',
    owner   => 'root',
    group   => 'root',
    mode    => 755,
  }
  exec { "Backup ${key_name} keys" :
    command  => "/usr/local/sbin/backup_ssh_keys.sh ${key_name}",
    cwd      => $key_dir,
    provider => 'shell',
    creates  => [
      "${host_key_dir}/${key_name}",
      "${host_key_dir}/${key_name}.pub",
    ],
    require  => [
      Exec["Generate '${key_name}' keypair"],
      File[$host_key_dir],
      File['Backup keys script'],
    ],
  }

  # Output the public key
  exec {'local-dev deploy key':
    command     => "\
echo '*******************************************************************************'\n
echo ' Add the following deploy key to your project on GitLab:'\n
echo '' `cat ${key_dir}/${key_name}.pub`\n
echo '*******************************************************************************'\n
",
    loglevel    => 'alert',
    logoutput   => true,
#    user        => $aegir_user,
#    environment => "HOME=${aegir_root}",
#    path        => ['/bin', '/usr/bin'],
    require  => [
      Exec["Generate '${key_name}' keypair"],
      File[$host_key_dir],
      File['Backup keys script'],
    ],
  }


}
