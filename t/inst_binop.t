#!/bin/sh
#
# Test that binary operators in strange cases work. Includes enums and globals.
#
echo 1..3

. test/utils.sh
setup

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

int main(void) {citrun_start();++_citrun[13];
	if ((++_citrun[14], (++_citrun[14], 4 + 3)))
		return (++_citrun[15], 0);
}
EOF

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
        18 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         1 If statements
         1 Return statement values
         7 Total statements
         1 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c enum.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff enum.c 2
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
