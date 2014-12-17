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
    git remote add -f avahi-aliases git@git.poeticsystems.com:valkyrie/provision_avahi.git
    git subtree add --prefix modules/avahi avahi-aliases master --squash
    # Supervisor
    git remote add -f puppet-supervisor https://github.com/GetValkyrie/puppet-module-supervisor.git
    git subtree add --prefix modules/supervisor puppet-supervisor process_name --squash

To pull down updates to an upstream project, I ran this:

    git subtree pull --prefix modules/avahi avahi-aliases master --squash

To push changes back upstream, I ran the following:

    git subtree push --prefix modules/avahi avahi-aliases master

That is, I added the remote to my local repo, and pushed the changes back up to
the remote.
