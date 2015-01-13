api = 2
core = 7.x

projects[] = drupal

<?php
  if ($profile && !in_array($profile, array('minimal', 'standard'))) {
    print("projects[$profile][type] = profile\n");
  }
?>
