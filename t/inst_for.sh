#
# Test that for loop condition instrumenting works.
#
echo 1..3
. test/utils.sh

cat <<EOF > for.c
int main(int argc, char *argv[]) {
	for (;;);

	for (argc = 0; argc < 10; argc++)
		argv++;
}
EOF

cat <<EOF > for.c.inst_good
int main(int argc, char *argv[]) {++_citrun.data[0];
	for (;;);

	for ((++_citrun.data[3], argc = 0); (++_citrun.data[3], (++_citrun.data[3], argc < 10)); argc++)
		argv++;
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
         7 Lines of source code
         1 Function definitions
         1 For loops
        15 Total statements
         2 Binary operators
EOF

$CITRUN_TOOLS/citrun-inst -c for.c > citrun.log
$CITRUN_TOOLS/citrun-check > check.out

inst_diff for.c 2
check_diff 3
