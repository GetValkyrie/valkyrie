Feature: Drush help for Valkyrie
  In order to see how to use the Valkyrie commands
  As a Drush user
  I need to be able to list the Valkyrie commands

Scenario: List all Valkyrie commands
  Given I run drush "help --filter=valkyrie"
  Then drush output should contain "valkyrie-new"
