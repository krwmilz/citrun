#!/bin/sh -e
echo 1..5

. test/utils.sh
setup

cat <<EOF > main.c
int main(void) { return 0; }
EOF
echo "ok 2 - source files wrote"

# Check that a command as simple as this works.
#
$TEST_TOOLS/citrun-wrap cc main.c
echo "ok 3 - source compiled"

$TEST_TOOLS/citrun-check > citrun-check.txt
echo "ok 4 - processed citrun.log"

cat <<EOF > citrun-check.txt.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Forked compilers
         1 Instrument successes
         1 Application link commands

Totals:
         2 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

diff -u citrun-check.txt.good citrun-check.txt
echo "ok 5 - citrun.log diff"
