#!/bin/sh
#
# Test that not having PATH set errors out.
#
echo 1..3

. test/utils.sh
setup

# Save locations to tools because after unset PATH they are not available.
grep=`which grep`

unset PATH
$TEST_TOOLS/gcc -c nomatter.c

[ $? -eq 1 ] && echo ok 2
$grep -q "Error: PATH is not set" citrun.log && echo ok 3
