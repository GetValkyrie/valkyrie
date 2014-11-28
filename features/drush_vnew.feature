@vnew
Feature: Create a new Valkyrie project
  In order to start using Valkyrie
  As a Drush user
  I need to be able to create a new Valkyrie project

@wip
Scenario: Call the valkyrie-new command
  Given I run drush "valkyrie-new /tmp/test_project"
  Then drush output should contain ""
  And drush output should contain "path"
  And drush output should contain "Options:"
  And drush output should contain "--commit"
  And drush output should contain "Aliases: vnew"
