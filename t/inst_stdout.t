#!/bin/sh
echo 1..3

. test/utils.sh
setup

cat <<EOF > hello.c
#include <stdio.h>

int
main(void)
{
	printf("hello, world!");
	return 0;
}
EOF

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Forked compilers
         1 Instrument successes
         1 Application link commands

Totals:
         9 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         1 Return statement values
         1 Call expressions
         9 Total statements
EOF

$TEST_TOOLS/citrun-wrap cc -o hello hello.c
$TEST_TOOLS/citrun-check > check.out

export CITRUN_SOCKET=
[ "`./hello`" = "hello, world!" ] && echo ok program prints

diff -u check.good check.out && echo ok citrun-check diff
