# Configures Vagrant to use the vagrant-sshfs plugin based on Valkyrie project
# settings.
# Params:
# +config+:: The Vagrant config object.
# +conf+:: A Valkyrie project configuration array.
def configure_vagrant_sshfs(config, conf)
  config.trigger.before [:up, :reload, :resume] do
    # Create local sshfs paths. This avoids superfluous prompts.
    create_sshfs_paths(conf['sshfs_paths'])
  end

  config.trigger.after [:up, :reload, :resume] do
    # Mount platforms and aliases via SSHFS
    system 'vagrant sshfs'
  end

  config.trigger.before [:halt, :suspend, :destroy] do
    # Unmount SSHFS paths
    umount_sshfs_paths(conf['sshfs_paths'])
  end
end

# Create local sshfs paths.
# Params:
# +sshfs_path+:: A hash of paths to be created
def create_sshfs_paths(sshfs_paths)
  sshfs_paths.each do |guest_path, host_path|
    if !Dir.exists?(host_path)
      Dir.mkdir(host_path)
    end
  end
end

# Unmount sshfs paths using the approriate command
# Params:
# +sshfs_path+:: A hash of paths mounted via sshfs
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
