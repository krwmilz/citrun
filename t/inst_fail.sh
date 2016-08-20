#
# Check that a program that won't compile natively is handled properly.
#
echo 1..4
. test/utils.sh

echo "int main(void) { return 0; " > bad.c

$TEST_TOOLS/citrun-wrap gcc -c bad.c 2> err.out
[ $? -eq 1 ] && echo ok 2

grep -q "error: expected" err.out && echo ok 3

cat <<EOF > check.good
Summary:
         1 Calls to the rewrite tool
         1 Source files used as input
         1 Rewrite parse errors
         1 Rewrite failures

Totals:
         2 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF

$TEST_TOOLS/citrun-check > check.out
check_diff 4
