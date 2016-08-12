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
$TEST_TOOLS/gcc -c nomatter.c 2> err.out

[ $? -eq 1 ] && echo ok 2
$grep -q "PATH must be set" err.out && echo ok 3
