#!/bin/sh -u
#
# Make sure that switch statement condition instrumentation works.
#
. t/utils.subr
plan 5

modify_PATH
enter_tmpdir

cat <<EOF > switch.c
int main(void) {
	int i;

	switch (i) {
	case 0:
		break;
	case 1:
		break;
	}

	return 0;
}
EOF

cat <<EOF > switch.c.inst_good
int main(void) {++_citrun.data[0];
	int i;

	switch ((++_citrun.data[3], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun.data[10], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
        13 Lines of source code
         1 Function definitions
         1 Switch statements
         1 Return statement values
        14 Total statements
EOF

ok "citrun-inst" citrun-inst -c switch.c
ok "citrun-check" citrun-check -o check.out

strip_preamble switch.c
strip_millis check.out

ok "citrun-inst output diff" diff -u switch.c.inst_good switch.c.citrun_nohdr
ok "citrun-check diff" diff -u check.good check.out
