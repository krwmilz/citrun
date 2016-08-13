#!/bin/sh
#
# Check that return statement values (if any) are instrumented correctly.
#
echo 1..3
. test/utils.sh

cat <<EOF > return.c
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF

cat <<EOF > return.c.inst_good
int foo() {++_citrun[0];
	return (++_citrun[1], 0);
}

int main(void) {citrun_start();++_citrun[4];
	return (++_citrun[5], 10);

	return (++_citrun[7], (++_citrun[7], 10 + 10));

	return (++_citrun[9], (++_citrun[9], foo()));
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
        12 Lines of source code
         1 Functions called 'main'
         2 Function definitions
         4 Return statement values
         1 Call expressions
        14 Total statements
         1 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c return.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff return.c 2
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
