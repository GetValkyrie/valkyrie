require 'yaml'

def load_config
  project_root = ENV['project_root']
  valkyrie_root = ENV['valkyrie_root']

  # Load default config
  conf = YAML.load_file("#{valkyrie_root}/config.yaml")
  # Merge in project-specific settings
  if File.exist?("#{project_root}/.valkyrie/config.yaml")
    conf.merge!(YAML.load_file("#{project_root}/.valkyrie/config.yaml"))
  end
  # Merge in any custom settings
  if File.exist?("#{project_root}/config.yaml")
    conf.merge!(YAML.load_file("#{project_root}/config.yaml"))
  end
  return conf
end
