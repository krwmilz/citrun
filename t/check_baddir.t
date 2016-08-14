#!/bin/sh
#
# Verify that passing a bad directory to citrun-check errors out.
#
echo 1..2
. test/utils.sh

$TEST_TOOLS/citrun-check some_nonexistent_dir > check.out

cat <<EOF > check.good
citrun-check: some_nonexistent_dir: no such directory
EOF

check_diff 2
