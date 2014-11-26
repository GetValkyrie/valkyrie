VALKYRIE
========

Valkyrie is a development toolkit for Drupal. It enables building and using a
local development environment built atop Vagrant and Aegir. Valkyrie supports
git- and Features-based workflows. These, in turn, enable teams to easily
collaborate and automate processes from development, through QA to deployment
and ongoing maintenance.


INSTALLATION
------------

Installing Valkyrie is as simple as:

    $ drush dl valkyrie

*N.B.* Valkyrie supports both Linux and OSX operating systems. We have no plans
to support Windows.


DEPENDENCIES
------------

Valkyrie is a Drush extension, and thus requires a recent version of Drush. We
currently recommend using Drush 7.x. Earlier versions *may* work, but are not
currently well-tested or supported. Note that Drush can be installed stand-
alone, if you are unable or unwilling to upgrade your system install.

 * https://github.com/drush-ops/drush#installupdate---a-global-drush-for-all-projects

Valkyrie depends on Vagrant, which in turn requires Virtualbox. These projects
publish their own packages for most operating systems. We recommend installing
these, as it will ensure that you are running on recent versions, and thus can
take advantage of newer features.

 * https://www.vagrantup.com/downloads.html
 * https://www.virtualbox.org/wiki/Downloads

Valkyrie also makes use of a couple Vagrant plugins: valkyrie-sshfs (a fork of
vagrant sshfs) and vagrant-dns (for Mac users only). Installing these should be
as simple as:

    $ vagrant plugin install valkyrie-sshfs
    $ vagrant plugin install vagrant-dns

Valkyrie-sshfs, in turn, requires SSHFS and thus FUSE. These have packages
available on most flavours of Linux and OSX:

    # apt-get install sshfs     # Debian, Ubuntu and other derivatives
    # yum install fuse-sshfs    # CentOS, RHEL, etc.
    # brew install sshfs        # OSX

Valkyrie also uses git quite extensively. So if you don't already have it
installed, go ahead and do that next.

 * http://git-scm.com/downloads


USAGE
-----

Valkyrie provides a number of Drush commands, which are well documented within
Drush itself. Run the following to review these commands:

    $ drush help --filter=valkyrie

These break down into three categories:

 * Setting up a project
 * Building a platform (Drupal code-base) and site.
 * Tools to ease development


### Project setup

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
will copy in a fresh version of Valkyrie from the recently update Drush
entension.

To apply any changes in VM configuration, re-run the provisioners in Vagrant:

    $ vagrant provision

If there's any reason to rollback from an update, you should be able to use
git, like so:

    $ git checkout .valkyrie/valkyrie


### Building a platform and site

(deploy key)

valkyrie-generate-platform (vgp)  Generate a platform.


### Development extras

valkyrie-logs (vlog)              Tail the Apache error log.
valkyrie-sql-snapshot (vss)       Cache a sql-dump for later diff'ing.
valkyrie-sql-diff (vsd)           Diff the current sql-dump with an earlier
                                  snapshot.

