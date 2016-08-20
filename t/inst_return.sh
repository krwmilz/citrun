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
int foo() {++_citrun.data[0];
	return (++_citrun.data[1], 0);
}

int main(void) {++_citrun.data[4];
	return (++_citrun.data[5], 10);

	return (++_citrun.data[7], (++_citrun.data[7], 10 + 10));

	return (++_citrun.data[9], (++_citrun.data[9], foo()));
}
EOF

cat <<EOF > check.good
Summary:
         1 Calls to the rewrite tool
         1 Source files used as input
         1 Rewrite successes

Totals:
        12 Lines of source code
         2 Function definitions
         4 Return statement values
         1 Call expressions
        14 Total statements
         1 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c return.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff return.c 2
check_diff 3
