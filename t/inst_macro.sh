#!/bin/sh -u
#
# Test for some tricky macro situations. In particular macro expansions at the
# end of binary operators.
#
. t/libtap.subr
. t/utils.subr
plan 5

modify_PATH
enter_tmpdir

cat <<EOF > macro.c
#define MAYBE 1023;

int main(int argc, char *argv[]) {
	int abd = 1023 + MAYBE;
	return 0;
}
EOF

cat <<EOF > macro.c.inst_good
#define MAYBE 1023;

int main(int argc, char *argv[]) {++_citrun.data[2];
	int abd = 1023 + MAYBE;
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
         1 Return statement values
         7 Total statements
EOF

ok "running citrun-inst" citrun-inst -c macro.c
ok "running citrun-check" citrun-check -o check.out

strip_preamble macro.c
strip_millis check.out

ok "known good instrumented diff" diff -u macro.c.inst_good macro.c.citrun_nohdr
ok "citrun-check diff" diff -u check.good check.out
