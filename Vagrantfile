# -*- mode: ruby -*-
# vi: set ft=ruby :

# Check that our required plugins are installed.
unless Vagrant.has_plugin?("vagrant-sshfs")
  raise 'The vagrant-sshfs plugin is not installed! (HINT: run "vagrant plugin install vagrant-sshfs")'
end
unless Vagrant.has_plugin?("vagrant-triggers")
  raise 'The vagrant-triggers plugin is not installed! (HINT: run "vagrant
  plugin install vagrant-triggers")'
end

Vagrant.configure(2) do |config|
  # Since we change the SSH user, we need to first install a public key. This
  # is done on the initial provisioning, which needs to run as the 'vagrant'
  # user. So, we switch based on the presence of a semaphore file, which we
  # create on provisioning, and remove after destroy.
  project_root = File.expand_path(File.dirname(__FILE__))
  first_run = !File.file?("#{project_root}/.first_run_complete")
  config.trigger.after [:destroy] do
    system("rm .first_run_complete > /dev/null 2>&1; echo '==> Removing .first_run_complete'")
  end

  hostname = "aegir3.local"

  # Silence annoying and spurious warnings
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.ssh.forward_agent = true

  config.vm.define "default" do |vm1|

    vm1.vm.hostname = hostname

    vm1.vm.provider "virtualbox" do |vbox|
      vbox.memory = "1024"
    end

    #vm1.vm.box = "ubuntu/trusty64"
    vm1.vm.box = "hashicorp/precise64"

    vm1.vm.network "private_network", ip: "10.42.0.10"

    if !first_run
      # Mount platforms via SSHFS
      config.sshfs.paths = { "/var/aegir/platforms" => "./platforms" }
      config.sshfs.enabled = false
      config.sshfs.username = "aegir"
      # SSH as the 'aegir' user
      config.ssh.username = 'aegir'
      config.ssh.private_key_path = '~/.ssh/id_rsa'
    end

    vm1.vm.provision "file",
      source: "~/.ssh/id_rsa.pub",
      destination: "/vagrant/authorized_keys",
      run: "always"

    vm1.vm.provision "puppet",
      module_path: "modules",
      facter: { "fqdn" => hostname },
      run: "always"

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
