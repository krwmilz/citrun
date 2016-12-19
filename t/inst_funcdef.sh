#!/bin/sh -u
#
# Check that really long function declarations are instrumented properly.
#
. t/utils.subr
plan 5

enter_tmpdir

cat <<EOF > funcdef.c
void

other(int a,
	int b)


{
}
EOF

cat <<EOF > funcdef.c.inst_good
void

other(int a,
	int b)


{++_citrun.data[0];++_citrun.data[1];++_citrun.data[2];++_citrun.data[3];++_citrun.data[4];++_citrun.data[5];++_citrun.data[6];
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
         9 Lines of source code
         1 Function definitions
         1 Total statements
EOF

ok "running citrun-inst" citrun-inst -c funcdef.c
ok "running citrun-check" citrun-check -o check.out

strip_preamble funcdef.c
strip_millis check.out

ok "known good instrumented diff" diff -u funcdef.c.inst_good funcdef.c.citrun_nohdr
ok "citrun-check diff" diff -u check.good check.out
