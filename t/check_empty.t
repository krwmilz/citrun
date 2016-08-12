#!/bin/sh
echo 1..2

. test/utils.sh
setup

$TEST_TOOLS/citrun-check > check.out

cat <<EOF > check.good
Checking .done

Summary:
         0 Log files found
EOF

diff -u check.good check.out && echo ok
