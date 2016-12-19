#!/bin/sh -u
#
# Check that the most basic of compile command lines works.
#
. t/utils.subr
plan 4


cat <<EOF > main.c
int main(void) { return 0; }
EOF

ok "wrapping simple build command" citrun-wrap cc main.c

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         2 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

ok "running citrun-check" citrun-check -o check.out
strip_millis check.out
ok "citrun-check diff" diff -u check.good check.out
