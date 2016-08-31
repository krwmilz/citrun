#!/bin/sh
#
# Check that a simple program can execute successfully with instrumentation.
#
. test/utils.sh
plan 7

cat <<EOF > fib.c
#include <stdio.h>
#include <stdlib.h>

int fibonacci(int n) {
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(int argc, char *argv[]) {
	int n;

	if (argc != 2)
		return 1;

	n = atoi(argv[1]);
	printf("%i", fibonacci(n));

	return 0;
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
        24 Lines of source code
         2 Function definitions
         3 If statements
         5 Return statement values
         5 Call expressions
        64 Total statements
         7 Binary operators
EOF

ok "wrapped source compile" $CITRUN_TOOLS/citrun-wrap cc -o fib fib.c
ok "running citrun-check" $CITRUN_TOOLS/citrun-check -o check.out

strip_millis check.out
ok "citrun-check diff" diff -u check.good check.out

ok_program "fib with no args" 1 "" fib
ok_program "fib of 10" 0 "55" fib 10
ok_program "fib of 20" 0 "6765" fib 20
