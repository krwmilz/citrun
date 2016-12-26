#!/bin/sh -u
#
# Check that the most basic of compile command lines works.
#
. t/utils.subr
plan 4

empty_main

ok "is instrumented compile successful" cc main.c

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         6 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

ok "running citrun_check" citrun_check -o check.out
strip_millis check.out
ok "citrun_check diff" diff -u check.good check.out
