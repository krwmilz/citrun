#
# Make sure that while loop condition instrumentation works.
#
echo 1..3
. test/utils.sh

cat <<EOF > while.c
int main(int argc, char *argv[]) {
	while (argc < 17)
		argc++;

	while ((argc && argv));
	return 0;
}
EOF

cat <<EOF > while.c.inst_good
int main(int argc, char *argv[]) {++_citrun.data[0];
	while ((++_citrun.data[1], (++_citrun.data[1], argc < 17)))
		argc++;

	while ((++_citrun.data[4], ((++_citrun.data[4], argc && argv))));
	return (++_citrun.data[5], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
         8 Lines of source code
         1 Function definitions
         2 While loops
         1 Return statement values
        18 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c while.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff while.c 2
check_diff 3
