# Configures Vagrant to use the vagrant-dns plugin based on Valkyrie project
# settings.
# Params:
# +config+:: The Vagrant config object.
# +conf+:: A Valkyrie project configuration array.
def configure_vagrant_dns(config, conf)

  if conf['use_vagrant_dns']
    # Set hostname
    config.vm.hostname = "#{conf['name']}.#{conf['tld']}"

    # Setup DNS server to resolve our TLD
    config.dns.tld = conf['tld']
    config.dns.patterns = ["/^.*.#{conf['tld']}$/"]

    config.trigger.after [:up, :reload, :resume] do
      puts 'Installing DNS resolver...'
      system 'vagrant dns --install --with-sudo'
      system 'vagrant dns --start'
    end

    config.trigger.before [:halt, :suspend] do
      # Stop DNS server
      system 'vagrant dns --stop'
    end

    config.trigger.after [:destroy] do
      # Remove vagrant-dns TLDs
      puts 'Removing DNS resolver files...'
      system 'vagrant dns --purge --with-sudo'
      system 'vagrant dns --stop'
    end
  end

end

# Document steps to install vagrant-dns plugin.
# Params:
# +config+:: The Vagrant config object.
# +conf+:: A Valkyrie project configuration array.
def install_vagrant_dns(conf)
  if (/darwin/ =~ RUBY_PLATFORM) != nil and conf['use_vagrant_dns']
    puts 'The vagrant-dns plugin does not appear to be installed.'
    puts 'To install it, run the following command:'
    puts
    puts '    vagrant plugin install vagrant-dns'
    puts
    puts 'This error can be suppressed by adding the following line to config.yml at'
    puts 'the root of your project:'
    puts
    puts '    use_vagrant_dns: false'
    puts
    abort()
  end
end

# Fallback to Avahi aliases generated and announced by Aegir in the VM.
# Params:
# +config+:: The Vagrant config object.
# +conf+:: A Valkyrie project configuration array.
def avahi_fallback(config, conf)
  config.vm.hostname = conf['name']+'.local'
end
