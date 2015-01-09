# Register our project as a place for Drush to find aliases.
def drush_aliases(config, conf)
  if conf['manage_drushrc_aliases']
    aliases_path = "#{conf['project_root']}/.valkyrie/cache/aliases"
    script_path = "#{conf['project_root']}/.valkyrie/valkyrie/vagrant/bin"

    config.trigger.after [:up, :reload, :resume] do
      # Set up drush aliases
      system "drush --yes #{script_path}/set_alias_path.php #{aliases_path}"
    end

    config.trigger.after [:suspend, :halt, :destroy] do
      # Remove drush aliases
      system "drush --yes #{script_path}/unset_alias_path.php #{aliases_path}"
    end
  end
end
