#!/bin/sh -e
echo 1..5

. test/utils.sh
setup

cat <<EOF > main.c
int
main(void)
{
	return 0;
}
EOF
echo "ok 2 - source files wrote"

# Check that a command as simple as this works.
#
cc main.c
echo "ok 3 - source compiled"

citrun-check | sed -e "s,'.*',''," > citrun-check.txt
echo "ok 4 - processed citrun.log"

cat <<EOF > citrun-check.txt.good
Checking '' .Done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Forked compilers
         1 Instrument successes
         1 Application link commands

Totals:
         6 Lines of source code
        32 Lines of instrumentation header
         1 Functions called ''
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

diff -u citrun-check.txt.good citrun-check.txt
echo "ok 5 - citrun.log diff"
