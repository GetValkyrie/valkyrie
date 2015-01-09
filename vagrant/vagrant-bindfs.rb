# Configures Vagrant to use the vagrant-bindfs plugin based on Valkyrie project
# settings.
# Params:
# +config+:: The Vagrant config object.
# +conf+:: A Valkyrie project configuration array.
def configure_vagrant_bindfs(config, conf)
  if conf['use_vagrant_bindfs']
    config.trigger.before [:up, :reload] do
      # Create local bindfs paths. This avoids superfluous prompts.
      create_bindfs_paths(conf['bindfs_paths'])
    end
    config.trigger.after [:destroy] do
      # Clean up local bindfs paths. If we don't explicitely remove these, then
      # they persist across restarts and cause issues with zombie aliases.
      delete_bindfs_paths(conf['bindfs_paths'])
    end
  end
end

# Create local bindfs paths.
# Params:
# +bindfs_paths+:: A hash of paths to be created
def create_bindfs_paths(bindfs_paths)
  bindfs_paths.each do |guest_path, host_path|
    if !Dir.exists?(host_path)
      system 'mkdir', '-p', host_path
    end
  end
end

# Delete local bindfs paths.
# Params:
# +bindfs_paths+:: A hash of paths to be created
def delete_bindfs_paths(bindfs_paths)
  bindfs_paths.each do |guest_path, host_path|
    if Dir.exists?(host_path)
      system 'rm', '-rf', host_path
    end
  end
end


# Document steps to install valkyrie-sshfs plugin.
# Params:
# +conf+:: A Valkyrie project configuration array.
def install_vagrant_bindfs(conf)
  if conf['use_valkyrie_sshfs']
    puts 'The valkyrie-sshfs plugin does not appear to be installed.'
    puts 'To install it, run the following command:'
    puts
    puts '    vagrant plugin install valkyrie-sshfs'
    puts
    puts 'This error can be suppressed by adding the following line to config.yml at'
    puts 'the root of your project:'
    puts
    puts '    use_valkyrie_sshfs: false'
    puts
    abort()
  end
end

