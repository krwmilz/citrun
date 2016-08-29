#!/bin/sh
#
# Test that for loop condition instrumenting works.
#
. test/utils.sh
plan 4

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

ok "running citrun-inst" $CITRUN_TOOLS/citrun-inst -c for.c
ok "running citrun-check" $CITRUN_TOOLS/citrun-check -f

remove_preamble for.c
ok "known good instrumented diff" diff -u for.c.inst_good for.c.citrun_nohdr
ok "citrun-check diff" diff -u check.good check.out
