#!/bin/sh
echo 1..3

. test/utils.sh
setup

echo "int main(void) { return 0; " > bad.c

$TEST_TOOLS/citrun-wrap gcc -c bad.c 2> err.out
[ $? -eq 1 ] && echo ok 2
grep -q "error: expected" err.out && echo ok 3

$TEST_TOOLS/citrun-check
