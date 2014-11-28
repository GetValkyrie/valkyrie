<?php

use Drupal\DrupalExtension\Context\RawDrupalContext;
use Drupal\DrupalExtension\Context\DrushContext;
use Behat\Behat\Context\SnippetAcceptingContext;
use Behat\Gherkin\Node\PyStringNode;
use Behat\Gherkin\Node\TableNode;
#use Behat\Testwork\Hook\Scope;

/**
 * Defines application features from the specific context.
 */
class FeatureContext extends RawDrupalContext implements SnippetAcceptingContext {

  /**
   * Initializes context.
   *
   * Every scenario gets its own context instance.
   * You can also pass arbitrary arguments to the
   * context constructor through behat.yml.
   */
  public function __construct() {
  }


  /**
   * @AfterSuite
   */
  public static function teardown(Behat\Testwork\Hook\Scope\AfterSuiteScope $scope) {
    // remove the test environment
    $old = getcwd(); // Save the current directory
    $test_project_path = '/tmp/test_project';
    chdir($test_project_path);
    system('vagrant destroy -f');
    chdir($old);
    system("rm -rf $test_project_path");
  }

}
