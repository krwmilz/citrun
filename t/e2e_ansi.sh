#!/bin/sh -u
#
# Check that instrumentation works when the -ansi flag is passed during
# compilation.
#
. t/utils.subr
plan 4


cat <<EOF > main.c
int
main(void) {
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
         5 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

ok "is compile successful" citrun_wrap cc -ansi -o main main.c
ok "is citrun_check exit 0" citrun_check -o check.out

strip_millis check.out
ok "is citrun_check output different" diff -u check.good check.out
