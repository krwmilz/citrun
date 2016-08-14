#!/bin/sh
#
# Check that really long function declarations are instrumented properly.
#
echo 1..3
. test/utils.sh

cat <<EOF > funcdef.c
void

other(int a,
	int b)


{
}
EOF

cat <<EOF > funcdef.c.inst_good
void

other(int a,
	int b)


{++_citrun[0];++_citrun[1];++_citrun[2];++_citrun[3];++_citrun[4];++_citrun[5];++_citrun[6];
}
EOF

cat <<EOF > check.good
Summary:
         1 Log files found
         1 Calls to the rewrite tool
         1 Source files used as input
         1 Rewrite successes

Totals:
         9 Lines of source code
         1 Function definitions
         1 Total statements
EOF

$TEST_TOOLS/citrun-inst -c funcdef.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff funcdef.c 2
check_diff 3
