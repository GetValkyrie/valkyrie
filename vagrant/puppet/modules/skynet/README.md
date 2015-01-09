Skynet
======

Skynet is an experimental replacement for the Aegir Hosting System's Queue
Daemon. It is written in Python using Cement (http://builtoncement.org).

It is currently an early prototype, and thus not even close to production
ready. There isn't yet a front-end, nor are most of the options for the
existing PHP queue daemon supported.


Dependencies
------------

Install pip, VirtualEnv and cement:

    # apt-get install python-pip python-dev build-essential python-mysqldb
    # pip install --upgrade pip
    # pip install --upgrade virtualenv
    # pip install cement


Installation
-----------

Eventually, we'll probably publish Skynet as pip and .deb packages. For now,
clone it from the github repository:

    $ cd /var/aegir
    $ git clone https://github.com/PraxisLabs/skynet.git


Configuration
-------------

Skynet requires a configuration file containing credentials to connect to
Aegir's database. This file should be at '~/skynet.conf' and look like:

    [database]
    host = localhost
    db = <aegir_site_db>
    user = <aegir_site_db_user>
    passwd = <aegir_site_db_password>

Eventually, the creation of this config file will be automated. However, for
the time-being, it has to be written manually. These credentials can be found
at the top of the Aegir front-end's drushrc.php, or in the site's vhost.


Usage
-----

Since Skynet is built on Cement, we are provided with a number of useful CLI
options by default, including a help option:

    $ ~/skynet/skynet.py -h

The only sub-command implemented so far is to run a queue daemon:

    $ ~/skynet/skynet.py queued

This command has a handy alias 'q', and can also be run in the background:

    $ ~/skynet/skynet.py q --daemon


--------------------------------------------------------------------------------
Author:    Christopher (ergonlogic) Gervais (mailto:chris@praxis.coop)
Copyright: Copyright (c) 2014 Praxis Laboratories Coop (http://praxis.coop)
License:   GPLv3 or later
