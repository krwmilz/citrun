#!/bin/sh -u
#
# Test that wrapping the 'cmake' build system produces instrumented binaries.
#
. t/libtap.subr
. t/utils.subr
plan 7

modify_PATH
enter_tmpdir

cat <<EOF > main.c
int
main(void)
{
	return 0;
}
EOF

cat <<EOF > CMakeLists.txt
cmake_minimum_required (VERSION 2.6)
project (program)
add_executable(program main.c)
EOF

ok "is cmake successful" citrun-wrap cmake .
ok "is make (from cmake) successful" citrun-wrap make
ok "is citrun-check successful" citrun-check -o check.out

cat <<EOF > check.good
Summary:
         3 Source files used as input
         3 Application link commands
         3 Rewrite successes
         3 Rewritten source compile successes

Totals:
      1085 Lines of source code
         3 Function definitions
         3 Return statement values
       101 Total statements
         9 Binary operators
EOF

strip_millis check.out
ok "is citrun-check output identical" diff -u check.good check.out

export CITRUN_PROCFILE="procfile.shm"
ok "does compiled program run" program
ok "is runtime shared memory file created" test -f procfile.shm
