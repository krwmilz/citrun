#
# Check that if statement conditions are instrumented properly.
#
echo 1..3
. test/utils.sh

cat <<EOF > if.c
int main(int argc, char *argv[]) {
	if (argc == 1)
		return 1;
	else
		return(14);

	if ((argc = 2))
		return 5;
	else
		return(0);
}
EOF

cat <<EOF > if.c.inst_good
int main(int argc, char *argv[]) {++_citrun.data[0];
	if ((++_citrun.data[1], (++_citrun.data[1], argc == 1)))
		return (++_citrun.data[2], 1);
	else
		return(++_citrun.data[4], (14));

	if ((++_citrun.data[6], ((++_citrun.data[6], argc = 2))))
		return (++_citrun.data[7], 5);
	else
		return(++_citrun.data[9], (0));
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
        12 Lines of source code
         1 Function definitions
         2 If statements
         4 Return statement values
        21 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c if.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff if.c 2
check_diff 3
