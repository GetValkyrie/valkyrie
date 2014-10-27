# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
plugins = YAML.load_file(File.dirname(__FILE__)+'/plugins.yaml')

re_run = FALSE

plugins.each do |plugin|
  name = plugin[0]
  source = ENV["project_root"] + plugin[1]['source']
  local = plugin[1]['local']
  # Check that our required plugins are installed.
  unless Vagrant.has_plugin?(name)
    puts "Installing the #{name} plugin."
    %x(vagrant plugin install #{source})
    re_run = TRUE
    puts 'Done!'
  end
  # Check local gem for update
  if local
    # Get the installed version
    installed = %x(vagrant plugin list | grep #{name})
    installed =~ /.*\((.*)\)/
    installed = $1
    # Get the available version
    gem_spec = YAML.load(%x(gem specification #{source}))
    available = gem_spec.version.to_s
    if available != installed
      puts "Updating #{name} gem to #{available}..."
      %x(vagrant plugin install #{source})
      puts "Done!"
      re_run = TRUE
    end
  end
end

if re_run
  puts 'Please run your vagrant command again.'
  exit
end

