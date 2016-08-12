#!/bin/sh -e
#
# Check that really long function declarations are instrumented properly.
#
echo 1..3

. test/utils.sh
setup

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
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
         9 Lines of source code
        32 Lines of instrumentation header
         1 Function definitions
         1 Total statements
EOF

$TEST_TOOLS/citrun-inst -c funcdef.c
$TEST_TOOLS/citrun-check > check.out

diff -u funcdef.c.inst_good funcdef.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
