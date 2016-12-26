#!/bin/sh -u
#
# Test that wrapping the 'make' build system produces instrumented binaries.
#
. t/utils.subr
type make || skip_all "make not found"
plan 6

empty_main

cat <<EOF > Makefile
program: main.o
	cc -o program main.o
EOF

ok "is instrumented make successful" make
ok "is citrun_check successful" citrun_check -o check.out

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

strip_millis check.out
ok "is citrun_check output identical" diff -u check.good check.out

ok "does compiled program run" ./program
ok "is runtime shared memory file created" test -f procdir/program_*
