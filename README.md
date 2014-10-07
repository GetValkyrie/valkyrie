Avahi Aliases
=============

This extension comprises several components. These include:

* A daemon to manage Avahi aliases.
* An extension to integrate with Aegir.
* Install Puppet module.

Avahi Aliases integrates with Aegir to allow automatic creation of such aliases
as sites are provisioned.


Install
=======

Avahi aliases service
---------------------

    # apt-get install python-avahi pip
    # pip install git+git://github.com/PraxisLabs/avahi-aliases.git

Aegir integration
-----------------

    # git clone git://github.com/PraxisLabs/avahi-aliases.git \
      /var/aegir/.drush/provision_avahi
    # cp /var/aegir/.drush/provision_avahi/files/aegir-avahi.sudoers \
      /etc/sudoers.d/aegir-avahi
    # chmod 440 /etc/sudoers.d/aegir-avahi
    # ln -s /var/aegir/config/avahi-aliases /etc/avahi/aliases.d/aegir

Puppet module
-------------

    # git clone git://github.com/PraxisLabs/avahi-aliases.git \
      <puppet_dir>/modules/avahi

Then simply include the avahi class:

    include avahi


Uninstall
==========

    sudo pip uninstall avahi-aliases


Usage
==========

Daemon Control
--------------

    # service avahi-aliases start
    # service avahi-aliases restart
    # service avahi-aliases stop

Creating Aliases
----------------

    # echo something.local >> /etc/avahi/aliases.d/default
    # service avahi-aliases restart

Notes:

* Aliases must end in `.local`
* One alias per line
* Blank lines and lines prefixed with `#` are ignored
* You must manually restart the daemon after modifying alias files

Aegir Integration
-----------------

Aegir integration is automatic, though you will need to clear the Drush
commandfile cache.


Todo
=====

1. implement `sudo avahi-alias add/remove aliasname`
2. implement `sudo avahi-alias list`


License
=======

Original copyright 2013 Zenobius Jiricek
see: https://github.com/airtonix/avahi-aliases

This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
Unported License. To view a copy of this license, visit:

    http://creativecommons.org/licenses/by-sa/3.0/.

Additional code is copyright 2014 Praxis Labs Coop, and published under the
GNU General Public License 3.0 or later http://www.gnu.org/copyleft/gpl.html.
