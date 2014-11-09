#!/bin/bash

vagrant up --provision
if [ "$?" -ne "0" ]
then
  echo "'vagrant up' failed. Leaving vm in place for forensic analysis."
  exit 1
fi

function do_as_aegir {
  cmd=$1;
  vagrant ssh -c "sudo -u root -s /bin/bash -c 'su aegir -l -c \"$cmd\"'";
}

# Upgrade
do_as_aegir "drush @hostmaster en --yes ctools"
do_as_aegir "wget http://drupalcode.org/project/provision.git/blob_plain/7.x-3.x:/upgrade.sh.txt -O upgrade.sh"
do_as_aegir "chmod \+x upgrade.sh"
vagrant ssh -c "sudo -u root -s /bin/bash -c 'cd /usr/share/drush/; git fetch; git checkout 6.x'";
yes | do_as_aegir "./upgrade.sh"


# Run tests
vagrant ssh -c "sudo -u root -s /bin/bash -c 'su aegir -l -c \"drush -y @hostmaster provision-tests-run\"'"
if [ "$?" -ne "0" ]
then
  echo "'provision-tests-run' failed. Leaving vm in place for forensic analysis."
  exit 1
fi

vagrant destroy --force
exit 0
