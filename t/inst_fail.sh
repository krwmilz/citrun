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

output_good="1 error generated.
Error while processing $tmpdir/bad.c.
bad.c: In function 'main':
bad.c:1: error: expected declaration or statement at end of input"

ok_program "wrapped failing native compile" 1 "$output_good" \
	citrun-wrap cc -c bad.c

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
