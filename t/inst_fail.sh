#!/bin/sh -u
#
# Check that a program that won't compile natively is handled properly.
#
. t/utils.subr
plan 4


echo "int main(void) { return 0; " > bad.c

cc -c bad.c 2> /dev/null
ok "is instrumented compile exit code 1" test $? -eq 1

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite failures

Totals:
         2 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

ok "running citrun_check" citrun_check -o check.out
strip_millis check.out
ok "citrun_check diff" diff -u check.good check.out
