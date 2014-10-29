#!/usr/bin/env drush
#<?php

$drushrc_path = getenv("HOME") . '/.drushrc.php';
$alias_path = drush_shift();
$alias_path_line = "\$options['alias-path'] = '$alias_path';";

if (file_exists($drushrc_path)) {
  $drushrc = file($drushrc_path, FILE_IGNORE_NEW_LINES);
  $alias_path_exists = FALSE;
  foreach ($drushrc as $index => $line) {
    if (strpos($line, $alias_path_line) !== FALSE) {
      return;   # The line exists; nothing more to do.
    }
    if (strpos($line, 'alias-path') !== FALSE) {
      $alias_path_exists = $index;
    }
  }
  drush_log('==> A drushrc file was found at: ' . $drushrc_path, 'ok');
  if ($alias_path_exists !== FALSE) {
    drush_log('==> An \'alias-path\' option already appears to exist in the following line:', 'warning');
    drush_log('==>    "' . $drushrc[$alias_path_exists] . '"', 'warning');
    if (!drush_confirm('Replace this line, and use the aliases in this project?')) {
      return;   # The user refused; nothing more to do.
    }
    else {
      $drushrc[$alias_path_exists] = $alias_path_line;
    }
  }
  else {
    if (!drush_confirm('Add an \'alias-path\' option, and use the aliases in this project?')) {
      return;   # The user refused; nothing more to do.
    }
    else {
      $drushrc[] = $alias_path_line;
    }
  }
}
else {
  drush_log('No drushrc file was found at: ' . $drushrc_path, 'ok');
  if (!drush_confirm('Create this file and use the aliases in this project?')) {
    return;   # The user refused; nothing more to do.
  }
  $drushrc = array(
    "<?php\n",
    $alias_path_line,
  );
}

file_put_contents($drushrc_path, implode("\n", $drushrc));
