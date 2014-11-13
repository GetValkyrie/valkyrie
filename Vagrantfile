# -*- mode: ruby -*-
# vi: set ft=ruby :

if Vagrant.has_plugin? 'vagrant-dns'
  hostname = 'valkyrie.val'
else
  hostname = 'valkyrie.local'
end

# Check that our required plugins are installed.
ENV['project_root'] = File.expand_path(File.dirname(__FILE__))
#require ENV['project_root'] + '/lib/plugins/plugins'

require 'yaml'
# Load default config
conf = YAML.load_file(ENV["project_root"] + '/lib/config.yaml')
# Merge in any custom settings
if File.exist?(ENV["project_root"] + '/config.yaml')
  conf.merge!(YAML.load_file(ENV["project_root"] + '/config.yaml'))
end

semaphore = "#{ENV["project_root"]}/.valkyrie/cache/first_run_complete"

def umount_sshfs_paths(sshfs_paths)
  # Determine the correct command to unmount sshfs directories
  if `which fusermount`.empty?
    umount_cmd = 'umount'
  else
    umount_cmd = 'fusermount -u -q'
  end

  sshfs_paths.each do |guest_path, host_path|
    system "#{umount_cmd} #{host_path} > /dev/null 2>&1; echo '==> Un-mounting #{host_path}'"
    system "rmdir #{host_path} > /dev/null 2>&1; echo '==> Removing #{host_path} mount-point'"
  end
end

Vagrant.configure(2) do |config|
  # Since we change the SSH user, we need to first install a public key. This
  # is done on the initial provisioning, which needs to run as the 'vagrant'
  # user. So, we switch based on the presence of a semaphore file, which we
  # create on provisioning, and remove after destroy.
  first_run = !File.file?(semaphore)

  config.trigger.before [:up, :reload, :resume] do
    # Setup drush aliases if the system has drush installed
    unless `which drush`.empty?
      aliases_path = ENV["project_root"] + '.valkyrie/.cache/aliases'
      system "drush ./lib/bin/set_alias_path.php #{aliases_path}"
    end
  end

  config.trigger.after [:up, :reload, :resume] do
    if Vagrant.has_plugin? 'vagrant-sshfs'
      system 'vagrant sshfs'
    end

    if Vagrant.has_plugin? 'vagrant-dns'
      puts 'Installing DNS resolver...'
      system 'vagrant dns --install'
      system 'vagrant dns --start'
    end
  end

  config.trigger.before [:halt, :suspend] do
      # Unmount SSHFS paths
      if Vagrant.has_plugin? 'vagrant-sshfs'
        umount_sshfs_paths(conf['sshfs_paths'])
      end

      # Stop DNS server
      if Vagrant.has_plugin? 'vagrant-dns'
        system 'vagrant dns --stop'
      end
  end

  config.trigger.after [:destroy] do
    # Remove semaphore file
    system "rm #{semaphore} > /dev/null 2>&1; echo '==> Removed semaphore file: #{semaphore}'"

    # Unmount SSHFS paths
    if Vagrant.has_plugin? 'vagrant-sshfs'
      umount_sshfs_paths(conf['sshfs_paths'])
    end

    # Remove vagrant-dns TLDs
    if Vagrant.has_plugin? 'vagrant-dns'
      puts 'Removing DNS resolver files...'
      system 'vagrant dns --purge'
      system 'vagrant dns --stop'
    end
  end


  if Vagrant.has_plugin? 'vagrant-dns'
    # Setup DNS server to resolve *.val
    config.dns.tld = 'val'
    config.dns.patterns = [/^.*\.val$/]
  end

  # Silence annoying and spurious warnings
  config.ssh.shell = 'bash -c "BASH_ENV=/etc/profile exec bash"'

  config.ssh.forward_agent = true

  config.vm.define 'default' do |vm1|

    vm1.vm.hostname = hostname

    vm1.vm.provider 'virtualbox' do |vbox|
      vbox.memory = '1024'
    end

    vm1.vm.box = 'hashicorp/precise64'

    vm1.vm.network 'private_network', ip: '10.42.0.10'

    if first_run
      vm1.vm.provision 'file',
        source: '~/.ssh/id_rsa.pub',
        destination: '/vagrant/.valkyrie/ssh/authorized_keys'
    else
      # Mount platforms and aliases via SSHFS
      config.sshfs.paths = conf['sshfs_paths']
      config.sshfs.enabled = false
      config.sshfs.username = 'aegir'

      # SSH as the 'aegir' user
      config.ssh.username = 'aegir'
      config.ssh.private_key_path = '~/.ssh/id_rsa'

      # Copy in some user-specific files to make the environment more familiar
      conf['dot_files'].each do |dot_file|
        real_dotfile = ENV['HOME']+'/'+dot_file
        if File.file?(real_dotfile)
          vm1.vm.provision 'file', source: real_dotfile,
            destination: "/var/aegir/#{dot_file}"
        end
      end
    end

    vm1.vm.provision 'puppet',
      module_path: 'lib/puppet/modules',
      manifests_path: 'lib/puppet/manifests',
      facter: { 'fqdn' => hostname },
      run: 'always'

  end
end
