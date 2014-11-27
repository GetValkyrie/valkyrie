Feature: Valkyrie Drush documentation
  In order to see how to use the Valkyrie commands
  As a Drush user
  I need to be able to read the documentation for the Valkyrie commands

Scenario: List all Valkyrie commands
  Given I run drush "help --filter=valkyrie"
  Then drush output should contain "valkyrie-clone-site"
  And drush output should contain "valkyrie-generate-pl"
  And drush output should contain "valkyrie-logs"
  And drush output should contain "valkyrie-new"
  And drush output should contain "valkyrie-sql-diff"
  And drush output should contain "valkyrie-sql-snapsho"
  And drush output should contain "valkyrie-update"

@vcs
Scenario: Read the valkyrie-clone-site command documentation
  Given I run drush "valkyrie-clone-site -h"
  Then drush output should contain "Arguments:"
  And drush output should contain "URL"
  And drush output should contain "git repo"
  And drush output should contain "Options:"
  And drush output should contain "--branch"
  And drush output should contain "--enable"
  And drush output should contain "--profile"
  And drush output should contain "Aliases: vcs"

@vgp
Scenario: Read the valkyrie-generate-platform command documentation
  Given I run drush "valkyrie-generate-platform -h"
  Then drush output should contain "Arguments:"
  And drush output should contain "name"
  And drush output should contain "makefile"
  And drush output should contain "Options:"
  And drush output should contain "--verify"
  And drush output should contain "Aliases: vgp"

@vlog
Scenario: Read the valkyrie-logs command documentation
  Given I run drush "valkyrie-logs -h"
  Then drush output should contain "Arguments:"
  And drush output should contain "log-file"
  And drush output should contain "Aliases: vlog"

@vnew
Scenario: Read the valkyrie-new command documentation
  Given I run drush "valkyrie-new -h"
  Then drush output should contain "Arguments:"
  And drush output should contain "path"
  And drush output should contain "Options:"
  And drush output should contain "--commit"
  And drush output should contain "Aliases: vnew"

@vsd
Scenario: Read the valkyrie-sql-diff command documentation
  Given I run drush "valkyrie-sql-diff -h"
  Then drush output should contain "Options:"
  And drush output should contain "--diff-cmd"
  And drush output should contain "--prompt"
  And drush output should contain "--snapshot-dir"
  And drush output should contain "--snapshot-file"
  And drush output should contain "Aliases: vsd"

@vss
Scenario: Read the valkyrie-sql-snapshot command documentation
  Given I run drush "valkyrie-sql-snapshot -h"
  Then drush output should contain "Options:"
  And drush output should contain "--snapshot-dir"
  And drush output should contain "--snapshot-file"
  And drush output should contain "Aliases: vss"

@vup
Scenario: Read the valkyrie-update command documentation
  Given I run drush "vup -h"
  Then drush output should contain "Aliases: vup"



