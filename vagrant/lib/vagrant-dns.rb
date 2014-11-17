name = File.basename(File.dirname(__FILE__))
config.vm.hostname = "#{name}.val"
# Setup DNS server to resolve *.val
config.dns.tld = 'val'
config.dns.patterns = [/^.*\.val$/]

config.trigger.after [:up, :reload, :resume] do
  puts 'Installing DNS resolver...'
  system 'vagrant dns --install'
  system 'vagrant dns --start'
end

config.trigger.before [:halt, :suspend] do
  # Stop DNS server
  system 'vagrant dns --stop'
end

config.trigger.after [:destroy] do
  # Remove vagrant-dns TLDs
  puts 'Removing DNS resolver files...'
  system 'vagrant dns --purge'
  system 'vagrant dns --stop'
end


