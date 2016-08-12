#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

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
Checking ..done

Summary:
         1 Log files found
         2 Source files input
         1 Calls to the instrumentation tool
         1 Forked compilers
         1 Instrument successes
         1 Application link commands

Totals:
         8 Lines of source code
        64 Lines of instrumentation header
         1 Functions called 'main'
         2 Function definitions
         2 Return statement values
         6 Total statements
EOF

$TEST_TOOLS/citrun-wrap cc -o main main.c other.c && echo "ok - source compiled"
$TEST_TOOLS/citrun-check > check.out

diff -u check.good check.out && echo ok - citrun-check diff
