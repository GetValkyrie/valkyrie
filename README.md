VALKYRIE
========

![valkyrie_logo](https://github.com/GetValkyrie/valkyrie/blob/0.3.x/assets/valkyrie_logo.png)
[![Join the chat at https://gitter.im/GetValkyrie/valkyrie](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/GetValkyrie/valkyrie?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Valkyrie is an opinionated development stack that makes features/git based Drupal development easy.


Features
--------

* Everything is wrapped up neatly in a VM. This keeps your computer tidy and Valkyrie consistent across various machines.
* Folders in the VM are mounted on your computer via NFS to make developing with your favorite editor easy (we like Vim).
* Automatic domain resolution using vagrant-dns on Macs or Avahi on Linux systems (we haven't tested this on Windows, sorry). Each site you create on Valkyrie will get an automatically resovling domain name which keeps you from needing to hack your /etc/hosts file.
* Drush extensions to make all kinds of common devleopment tasks easy.
* Automatic Drush aliases for running commands against sites inside the VM.

Prerequisites
-------------

We've tested this on OS X (Yosemite) and some flavor of linux that @ergonlogic uses. You'll need to have the following:

* [VirtualBox](https://www.virtualbox.org)
* [Vagrant](https://www.vagrantup.com)
* [vagrant-triggers](https://github.com/emyl/vagrant-triggers)
* [vagrant-dns](https://github.com/BerlinVagrant/vagrant-dns) *Mac only
* [Drush 7.0-dev](https://github.com/drush-ops/drush)

The latest versions of all of the above are recommended. To install Drush on OS X, we recommend using [Homebrew](http://brew.sh/). You'll need to install the HEAD version of Drush: `brew install drush --HEAD`.


Installation
------------

Make sure you have a .drush folder in your home diretory. If you don't, run the `drush` command and it should create one. To get Valkyrie installed, clone the repo inside ~/.drush like so: `git clone https://github.com/GetValkyrie/valkyrie.git ~/.drush/valkyrie --recursive`.


Usage
-----

Valkyrie provides a number of Drush commands, which are well documented within Drush itself. Run the following to review these commands:

`drush help --filter=valkyrie`

### Creating a project

To begin using Valkyrie you'll need to create a project. A project is a VM provisioned with the entire dev stack. You really only need one project since it will be running [Aegir](http://www.aegirproject.org) which supports multiple platforms/sites.

To create a project run `drush vnew [name]`. We usually name our project "valkyrie" since we only need one `drush vnew valkyrie`. This will create a folder named "valkyrie" in the current working directory and will spin up and provision a VM. This will take a while so go grab a coffee/beer.

During the provisioning process you should see a couple red notices. One is an SSH key for the VM in case you need to add it as a deploy key to private repos. The other is a login link for accessing Aegir.

### Help

* If Hosting Queue not running

	* `drush @vm cc drush; drush @v hosting-dispatch`

* If frontend does not generate properly

	* `drush @v provision-verify`

Upcoming Features
-----------------

* Platform management
* ??? - Request additional features in a PR. Even better, implement it in PR as well :)


Free Software
-------------

We are firm proponents of Free Software. Valkyrie only exists because of the
ongoing efforts of many other projects including: Aegir, Drupal, Drush, Git,
GNU/Linux, Ansible, Vagrant and VirtualBox.
