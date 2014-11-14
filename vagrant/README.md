Aegir3: Quick & Dirty
=====================

This project will install the latest Aegir 3.x in a Vagrant VM.


Installation
------------

Install Virtualbox and Vagrant as normal. Clone this repo, and run 'vagrant up'
in the project root. Vagrant will start up a VM, and install Aegir 3 and all
its dependencies. At the end of this process, it will print a red box listing a
URL to visit to login to your local Aegir 3 install.

Before opening the URL, add the following line to your /etc/hosts:

    10.42.0.10     aegir3.local

