#!/bin/sh
#
# Make sure that while loop condition instrumentation works.
#
. tlib/utils.sh
plan 5

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

ok "citrun-inst" $CITRUN_TOOLS/citrun-inst -c while.c
ok "citrun-check" $CITRUN_TOOLS/citrun-check -o check.out

strip_preamble while.c
strip_millis check.out

ok "citrun-inst diff" diff -u while.c.inst_good while.c.citrun_nohdr
ok "citrun-check diff" diff -u check.good check.out
