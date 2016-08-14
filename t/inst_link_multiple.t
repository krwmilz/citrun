#!/bin/sh
#
# Check that linking more than one instrumented object file together works.
#
echo 1..4
. test/utils.sh

cat <<EOF > one.c
void second_func();

int main(void) {
	second_func();
	return 0;
}
EOF

cat <<EOF > two.c
void third_func();

void second_func(void) {
	third_func();
	return;
}
EOF

cat <<EOF > three.c
void third_func(void) {
	return;
}
EOF

cat <<EOF > Jamfile
Main program : one.c two.c three.c ;
EOF

$TEST_TOOLS/citrun-wrap jam && echo "ok - source compiled"
$TEST_TOOLS/citrun-check > check.out && echo ok

cat <<EOF > check.good
Summary:
         1 Log files found
         3 Source files input
         4 Calls to the instrumentation tool
         3 Forked compilers
         3 Instrument successes
         1 Application link commands

Totals:
        18 Lines of source code
         1 Functions called 'main'
         3 Function definitions
         1 Return statement values
         2 Call expressions
        13 Total statements
EOF

check_diff 4
