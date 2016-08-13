#!/bin/sh -e
#
# Test for some tricky macro situations. In particular macro expansions at the
# end of binary operators.
#
echo 1..3
. test/utils.sh

cat <<EOF > macro.c
#define MAYBE 1023;

int main(int argc, char *argv[]) {
	int abd = 1023 + MAYBE;
	return 0;
}
EOF

cat <<EOF > macro.c.inst_good
#define MAYBE 1023;

int main(int argc, char *argv[]) {citrun_start();++_citrun[2];
	int abd = 1023 + MAYBE;
	return (++_citrun[4], 0);
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
         1 Return statement values
         7 Total statements
EOF

$TEST_TOOLS/citrun-inst -c macro.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff macro.c 2
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
