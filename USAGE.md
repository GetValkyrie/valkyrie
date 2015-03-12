VALKYRIE
========

USAGE
-----

Valkyrie provides a number of Drush commands, which are well documented within
Drush itself. Run the following to review these commands:

    $ drush help --filter=valkyrie

These break down into three categories:

 * Setting up a project
 * Building a platform (Drupal code-base) and site.
 * Tools to ease development


Project setup
-------------

Once you've installed Valkyrie and its dependencies, the first things you'll
want to do is create a new project. In this context, a 'project' is a directory
containing all the components required to launch and configure a local VM.

The 'drush valkyrie-new' command (aliased to 'vnew') will create such a
project. Besides creating the directory, this command will copy Valkyrie itself
into a hidden folder within the project. This ensures that the project will
keep running, regardless of updates to the Valkyrie Drush extension. This
directory's contents are committed into a git repository to make tracking
changes easier. Any customizations can be done here, in isolation from the
system install, and shared with other team members via git.

To launch the VM, just use Vagrant as normal:

    $ vagrant up

If you've updated the Valkyrie Drush extension (i.e., via 'drush dl valkyrie'),
you may want to update your projects to use some if the new code. Within a
project, this will affect mostly the Vagrantfile (and associated code) and the
Puppet code used to configure the VM. To update the Valkyrie code cached in a
project, run 'drush valkyrie-update' (or 'vup') from the project root. This
will copy in a fresh version of Valkyrie from the recently updated Drush
entension.

To apply any changes in VM configuration, re-run the provisioners in Vagrant:

    $ vagrant provision

If there is any reason to rollback from an update, you should be able to use
git, like so:

    $ git checkout .valkyrie/valkyrie


Building platforms and sites
----------------------------

valkyrie-generate-platform (vgp)  Generate a platform.
valkyrie-platform-rebuild (vpr)   Rebuild a site's platform.
valkyrie-site-clone (vsc)         Clone a site from a git repo.
valkyrie-site-generate (vsg)      Create and install a new git-based site.
valkyrie-site-reinstall (vsr)     Reinstall a site.


Development extras
------------------

valkyrie-logs (vlog)              Tail the Apache error log.
valkyrie-sql-snapshot (vss)       Cache a sql-dump for later diffing.
valkyrie-sql-diff (vsd)           Diff the current sql-dump with an earlier
                                  snapshot.

