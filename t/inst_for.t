#!/bin/sh -e
#
# Test that for loop condition instrumenting works.
#
echo 1..3

. test/utils.sh
setup

cat <<EOF > for.c
int main(int argc, char *argv[]) {
	for (;;);

	for (argc = 0; argc < 10; argc++)
		argv++;
}
EOF

cat <<EOF > for.c.inst_good
int main(int argc, char *argv[]) {citrun_start();++_citrun[0];
	for (;;);

	for ((++_citrun[3], argc = 0); (++_citrun[3], (++_citrun[3], argc < 10)); argc++)
		argv++;
}
EOF

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
         7 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         1 For loops
        15 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c for.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff for.c 2
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
