project_root = ENV['project_root']
valkyrie_root = ENV['valkyrie_root']
aliases_path = "#{project_root}/.valkyrie/cache/aliases"

# Register our project as a place for Drush to find aliases.
def drush_aliases(config)
  config.trigger.before [:up, :reload, :resume] do
    # Set up drush aliases
    system "drush #{valkyrie_root}/lib/bin/set_alias_path.php #{aliases_path}"
  end

  config.trigger.after [:destroy] do
    # Remove drush aliases
    system "drush #{valkyrie_root}/lib/bin/unset_alias_path.php #{aliases_path}"
  end

end
