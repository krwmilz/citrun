#!/bin/sh
#
# Check that two source files given on the same command line both get
# instrumented fully.
#
. test/utils.sh
plan 3

cat <<EOF > main.c
int main(void) {
	return 0;
}
EOF

cat <<EOF > other.c
int other(void) {
	return 0;
}
EOF

cat <<EOF > check.good
Summary:
         2 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         8 Lines of source code
         2 Function definitions
         2 Return statement values
         6 Total statements
EOF

ok "citrun-wrap compile" $CITRUN_TOOLS/citrun-wrap cc -o main main.c other.c
ok "citrun-check" $CITRUN_TOOLS/citrun-check -f

ok "citrun-check diff" diff -u check.good check.out
