#!/bin/sh
#
# Make sure that do while loop condition instrumentation works.
#
echo 1..3
. test/utils.sh

cat <<EOF > while.c
int main(int argc, char *argv[]) {
	do {
		argc++;
	} while (argc != 10);
	return 0;
}
EOF

cat <<EOF > while.c.inst_good
int main(int argc, char *argv[]) {citrun_start();++_citrun[0];
	do {
		argc++;
	} while ((++_citrun[3], (++_citrun[3], argc != 10)));
	return (++_citrun[4], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Calls to the rewrite tool
         1 Source files used as input
         1 Rewrite successes

Totals:
         7 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         1 Do while loops
         1 Return statement values
        11 Total statements
         1 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c while.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff while.c 2
check_diff 3
