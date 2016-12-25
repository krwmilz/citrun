#!/bin/sh -u
#
# Check that return statement values (if any) are instrumented correctly.
#
. t/utils.subr
plan 5


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

ok "running citrun_inst" citrun_inst -c return.c
ok "running citrun_check" citrun_check -o check.out

strip_preamble return.c
strip_millis check.out

ok "instrumented src diff" diff -u return.c.inst_good return.c.citrun_nohdr
ok "citrun_check diff" diff -u check.good check.out
