Hacking Puppet modules
======================

We use several Puppet modules in this project. In order to be able to pull in
changes from upstream, as well as contribute back our own improvements, we use
the 'git subtree' command, as described here:

* http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/

The commands I ran to initialize this setup were:

    # Aegir
    git remote add -f puppet-aegir ergonlogic@git.drupal.org:project/puppet-aegir.git
    git subtree add --prefix modules/aegir puppet-aegir 1.0.x --squash
    # Drush
    git remote add -f puppet-drush ergonlogic@git.drupal.org:project/puppet-drush.git
    git subtree add --prefix modules/drush puppet-drush 1.0.x --squash
    # Avahi Aliases
    git remote add -f avahi-aliases https://github.com/PraxisLabs/avahi-aliases.git
    git subtree add --prefix modules/avahi avahi-aliases master --squash


Hacking Vagrant Plugins
=======================

Likewise, we use several Vagrant plugins. Unlike the Puppet modules described
above, we are not the principal maintainers of these projects. That said, on
occasion we need to fix or enahance these projects. To run from a hacked
version of a Vagrant plugin, we need to build the gem locally. To do this, we
first add the plugin code as a library (again using git subtree):

    # Vagrant SSHFS
    git remote add -f vagrant-sshfs http://git.poeticsystems.com/valkyrie/vagrant-sshfs.git
    git subtree add --prefix lib/plugins/vagrant-sshfs vagrant-sshfs master --squash

Build the gem:

    cd lib/plugins/vagrant-sshfs
    gem build vagrant-sshfs.gemspec

Back in the project root, we can install the gem we just created with:

    vagrant plugin install lib/plugins/vagrant-sshfs/vagrant-sshfs-0.0.6.gem

Rather than requiring users to install these plugins themselves, we include
some code to install them automatically when a vagrant command is run. We
maintain a manifest of vagrant plugins to install in this way in:

    lib/plugins/plugins.yaml
