#!/bin/sh -u
#
# Check that a program that won't compile natively is handled properly.
#
. t/libtap.subr
. t/utils.subr
plan 4

modify_PATH
enter_tmpdir

echo "int main(void) { return 0; " > bad.c

citrun-wrap cc -c bad.c 2> /dev/null
ok "is citrun-wrap exit code 1" test $? -eq 1

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite parse errors
         1 Rewrite failures

Totals:
         2 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

ok "running citrun-check" citrun-check -o check.out
strip_millis check.out
ok "citrun-check diff" diff -u check.good check.out
