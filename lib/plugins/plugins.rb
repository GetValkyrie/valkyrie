# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
plugins = YAML.load_file(File.dirname(__FILE__)+'/plugins.yaml')

re_run = FALSE

plugins.each do |plugin|
  name = plugin[0]
  source = plugin[1]['source']
  # Check that our required plugins are installed.
  unless Vagrant.has_plugin?(name)
    puts "Installing the #{name} plugin."
    %x(vagrant plugin install #{source})
    re_run = TRUE
    puts 'Done!'
  end
end

if re_run
  puts 'Please run your vagrant command again.'
  exit
end

