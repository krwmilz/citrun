#!/bin/sh
#
# Make sure preprocessor flag (-E) causes no instrumentation to be done.
#
echo 1..3
. test/utils.sh

echo "int main(void) { return 0; }" > prepro.c

$TEST_TOOLS/citrun-wrap gcc -E prepro.c > combined.out 2>&1

[ $? -eq 0 ] && echo ok 2
grep -q "int main(void) { return 0; }" combined.out && echo ok 3
