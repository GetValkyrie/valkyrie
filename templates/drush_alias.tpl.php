<?php
/**
 * @file
 * Template file for a Drush alias file.
 */
print "<?php \n"; ?>
$aliases['<?php print $aliasname; ?>'] = <?php print var_export($options, TRUE); ?>;
