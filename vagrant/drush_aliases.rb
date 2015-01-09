# Register our project as a place for Drush to find aliases.
def drush_aliases(config, project_root)
  aliases_path = "#{project_root}/.valkyrie/cache/aliases"

  config.trigger.after [:up, :reload, :resume] do
    # Set up drush aliases
    system "drush #{project_root}/.valkyrie/valkyrie/vagrant/bin/set_alias_path.php #{aliases_path}"
  end

  config.trigger.after [:destroy] do
    # Remove drush aliases
    system "drush #{project_root}/.valkyrie/valkyrie/vagrant/bin/unset_alias_path.php #{aliases_path}"
  end

end
