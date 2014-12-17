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
