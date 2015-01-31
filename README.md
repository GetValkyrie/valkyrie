VALKYRIE
========

Valkyrie is an opinionated local dev stack that makes features/git based Drupal development easy.


Local codebase
--------------

Having to SSH into a development VM and edit code using a terminal-based editor
(such as vim) isn't everyone's cup of tea. Many IDEs support mounting remote
filesystems, but this can be tricky and needlessly time-consuming. Valkyrie
uses NFS to mount all your platforms directly on your host machine, which
allows you to use the same editor you're used to without jumping through hoops.


Local Domain Resolution
-----------------------

When building websites locally, it's common practice to add development domains
to /etc/hosts. This is fine, as far as it goes. But when you can spin up new
platforms and sites as easily as Valkyrie allows, that extra step starts to be
a hassle. Through the magic of Avahi (on Linux systems) or a vagrant-dns plugin (on
Macs), every site provisioned on Valkyrie automatically resolves to a local alias.


Site Configuration
------------------

Keeping site configuration and content separate can be a challenge. The
Features module goes a long way towards solving this issue, but it isn't always
obvious what to export to code. We've found that comparing database dumps is a
pretty good way to visualize these changes, and so we've added some commands to
make this quick and easy.


Platform Management
-------------------

The codebase of a modern Drupal site is complex. Maintaining the security
of the codebase requires frequent updates. We are striving to fully automate
such updates. While we aren't there yet, we've made things pretty easy. You can
expect significant further improvements in these features.


Free Software
-------------

We are firm proponents of Free Software. Valkyrie only exists because of the
ongoing efforts of many other projects including: Aegir, Drupal, Drush, Git,
GNU/Linux, Puppet, Vagrant and VirtualBox.
