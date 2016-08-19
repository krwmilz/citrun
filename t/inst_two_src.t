#!/bin/sh
#
# Check that two source files given on the same command line both get
# instrumented fully.
#
echo 1..3
. test/utils.sh

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
         1 Calls to the rewrite tool
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

$TEST_TOOLS/citrun-wrap cc -o main main.c other.c && echo "ok - source compiled"
$TEST_TOOLS/citrun-check > check.out

check_diff 3
