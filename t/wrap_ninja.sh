#!/bin/sh -u
#
# Test that wrapping the 'ninja' build system produces instrumented binaries.
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

# Quote the here-doc so that '$' does not get substituted.
cat <<'EOF' > build.ninja
rule cc
  command = gcc $cflags -c $in -o $out

rule link
  command = gcc $in -o $out

build main.o: cc main.c
build program: link main.o
EOF

ok "is ninja successful" citrun-wrap ninja
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

export CITRUN_PROCFILE="procfile.shm"
ok "does compiled program run" program
ok "is runtime shared memory file created" test -f procfile.shm
