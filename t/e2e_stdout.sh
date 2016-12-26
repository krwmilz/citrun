#!/bin/sh -u
#
# Simple program that prints output.
#
. t/utils.subr
plan 5


cat <<EOF > hello.c
#include <stdio.h>

int main(void) {
	printf("hello, world!");
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
         7 Lines of source code
         1 Function definitions
         1 Return statement values
         1 Call expressions
         9 Total statements
EOF

ok "is instrumented compile successful" cc -o hello hello.c

ok "citrun_check" citrun_check -o check.out
strip_millis check.out
ok "citrun_check diff" diff -u check.good check.out

ok_program "stdout compare" 0 "hello, world!" ./hello
