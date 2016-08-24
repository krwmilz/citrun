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
int main(int argc, char *argv[]) {++_citrun.data[0];
	do {
		argc++;
	} while ((++_citrun.data[3], (++_citrun.data[3], argc != 10)));
	return (++_citrun.data[4], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
         7 Lines of source code
         1 Function definitions
         1 Do while loops
         1 Return statement values
        11 Total statements
         1 Binary operators
EOF

$CITRUN_TOOLS/citrun-inst -c while.c > citrun.log
$CITRUN_TOOLS/citrun-check > check.out

inst_diff while.c 2
check_diff 3
