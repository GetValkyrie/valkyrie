#!/usr/bin/env drush
#<?php

$drushrc_path = getenv("HOME") . '/.drushrc.php';
$alias_path = drush_shift();
$alias_path_line = "\$options['alias-path'][] = '$alias_path';";

if (!file_exists($drushrc_path)) {
  // No ~/.drushrc.php, so nothing to remove.
  return;
}
else {
  $drushrc = file($drushrc_path, FILE_IGNORE_NEW_LINES);
  $alias_path_exists = FALSE;
  foreach ($drushrc as $index => $line) {
    if (strpos($line, $alias_path_line) !== FALSE) {
      unset($drushrc[$index]);
      file_put_contents($drushrc_path, implode("\n", $drushrc));
      drush_log('==> Removed alias-path to this project from drushrc file at: ' . $drushrc_path, 'ok');
      return;
    }
  }
}
