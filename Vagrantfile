# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  first_run = !File.file?('.first_run')

  hostname = "aegir3.local"

  # Silence annoying and spurious warnings
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.ssh.forward_agent = true

  config.vm.define "default" do |vm1|

    vm1.vm.hostname = hostname

    vm1.vm.box = "hashicorp/precise64"

    vm1.vm.network "private_network", ip: "10.42.0.10"

    if first_run
      vm1.vm.provision "file", source: "~/.ssh/id_rsa.pub",
        destination: "/vagrant/authorized_keys"
    else
      # Mount platforms via SSHFS
      config.sshfs.paths = { "/var/aegir/platforms" => "./platforms" }
      config.sshfs.username = "aegir"
      # SSH as the 'aegir' user
      config.ssh.username = 'aegir'
      config.ssh.private_key_path = '~/.ssh/id_rsa'
      #TODO: investigate why we need to restart this manually
      vm1.vm.provision "shell",
        inline: "service hosting-queued start"
    end

    vm1.vm.provision "puppet" do |puppet|
      puppet.module_path = "modules"
      puppet.facter = {
        "first_run" => first_run,
        "fqdn"      => hostname
      }
    end

    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end

    # Copy in some user-specific files to make the environment more familiar
#    vagrant_home = '/home/vagrant'
#    home_dirs = ['/root', '/var/aegir']
#    dot_files = ['.gitconfig', '.vimrc', '.bashrc']
#    dot_files.each do |dot_file|
#      vm1.vm.provision "file", source: "~/#{dot_file}",
#        destination: "#{vagrant_home}/#{dot_file}"
#      # Since the vagrant user doesn't have write access to other users' home
#      # directories, we need to copy them into place
#      home_dirs.each do |home_dir|
#        vm1.vm.provision "shell",
#          inline: "cp #{vagrant_home}/#{dot_file} #{home_dir}/#{dot_file}"
#      end
#    end

  end

end
