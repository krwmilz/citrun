#!/bin/sh
#
# Make sure that switch statement condition instrumentation works.
#
echo 1..3
. test/utils.sh

cat <<EOF > switch.c
int main(void) {
	int i;

	switch (i) {
	case 0:
		break;
	case 1:
		break;
	}

	return 0;
}
EOF

cat <<EOF > switch.c.inst_good
int main(void) {citrun_start();++_citrun[0];
	int i;

	switch ((++_citrun[3], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun[10], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Log files found
         1 Calls to the rewrite tool
         1 Source files used as input
         1 Rewrite successes

Totals:
        13 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         1 Switch statements
         1 Return statement values
        14 Total statements
EOF

$TEST_TOOLS/citrun-inst -c switch.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff switch.c 2
check_diff 3
