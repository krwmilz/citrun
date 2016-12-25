#!/bin/sh -u
#
# Test that binary operators in strange cases work. Includes enums and globals.
#
. t/utils.subr
plan 5


cat <<EOF > enum.c
enum ASDF {
	ONE = (1 << 0),
	TWO = (1 << 1),
	THR = (1 << 2)
};

static int foo = 5 + 5;

static const struct {
	int i;
	unsigned char data[0 + 64 * 6];
} blah;

int main(void) {
	if (4 + 3)
		return 0;
}
EOF

cat <<EOF > enum.c.inst_good
enum ASDF {
	ONE = (1 << 0),
	TWO = (1 << 1),
	THR = (1 << 2)
};

static int foo = 5 + 5;

static const struct {
	int i;
	unsigned char data[0 + 64 * 6];
} blah;

int main(void) {++_citrun.data[13];
	if ((++_citrun.data[14], (++_citrun.data[14], 4 + 3)))
		return (++_citrun.data[15], 0);
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Rewrite successes

Totals:
        18 Lines of source code
         1 Function definitions
         1 If statements
         1 Return statement values
         7 Total statements
         1 Binary operators
EOF

ok "running citrun_inst" citrun_inst -c enum.c
ok "running citrun_check" citrun_check -o check.out

strip_preamble enum.c
strip_millis check.out

ok "instrumented src file diff" diff -u enum.c.inst_good enum.c.citrun_nohdr
ok "citrun_check diff" diff -u check.good check.out
