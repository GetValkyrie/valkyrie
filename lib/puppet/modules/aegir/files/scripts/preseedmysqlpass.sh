#!/bin/sh

test -f /root/.my.cnf || exit 1

rootpw=$(grep password /root/.my.cnf | sed -e 's/^[^=]*= *\(.*\) */\1/')

debconf-set-selections <<EOF
aegir-hostmaster aegir/db_password string $rootpw
EOF

