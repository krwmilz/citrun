#!/bin/sh -u
#
# Test that wrapping the 'jam' build system produces instrumented binaries.
#
. t/libtap.subr
. t/utils.subr
plan 6

modify_PATH
enter_tmpdir

cat <<EOF > main.c
int
main(void)
{
	return 0;
}
EOF

cat <<EOF > Jamfile
Main program : main.c ;
EOF

ok "is jam successful" citrun-wrap jam
ok "is citrun-check successful" citrun-check -o check.out

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
ok "is citrun-check output identical" diff -u check.good check.out

CITRUN_PROCDIR="procdir/" ok "does compiled program run" program
ok "is runtime shared memory file created" test -f procdir/program_*
