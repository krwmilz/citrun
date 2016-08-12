#!/bin/sh -e
#
# Make sure that switch statement condition instrumentation works.
#
echo 1..3

. test/utils.sh
setup

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
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
        13 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         1 Switch statements
         1 Return statement values
        14 Total statements
EOF

$TEST_TOOLS/citrun-inst -c switch.c
$TEST_TOOLS/citrun-check > check.out

diff -u switch.c.inst_good switch.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
