# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  hostname = "aegir3.local"

  config.vm.define "default" do |vm1|

    vm1.vm.hostname = hostname
#    vm1.vm.synced_folder "aegir", "/var/aegir",
#      create: true
#      group: 'aegir',
#      owner: 'aegir'

    vm1.vm.box = "hashicorp/precise64"

    vm1.vm.network "private_network", ip: "10.42.0.10"

    vm1.vm.provision "puppet" do |puppet|
      puppet.module_path = "modules"
      puppet.manifests_path = "manifests"
      puppet.manifest_file  = "nodes.pp"
      puppet.facter = {
        "fqdn" => hostname
      }
    end

    config.vm.provider "virtualbox" do |v|
      v.memory = 1024
    end

  end

end

