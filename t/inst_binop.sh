#
# Test that binary operators in strange cases work. Includes enums and globals.
#
echo 1..3
. test/utils.sh

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

$TEST_TOOLS/citrun-inst -c enum.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff enum.c 2
check_diff 3
