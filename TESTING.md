VALKYRIE
========

TESTING
-------

We use Behat/Mink with the Drupal extension to run our tests.

To get started, install Composer and the require-dev components:

    $ curl http://getcomposer.org/installer | php
    $ php composer.phar install

To run the entire test suite, run:

    $ bin/behat

Tests for each command can be run individually using tags:

    $ bin/behat --tags @vnew
