#
# Check that the most basic of compile command lines works.
#
echo 1..4
. test/utils.sh

cat <<EOF > main.c
int main(void) { return 0; }
EOF
echo "ok 2 - source files wrote"

$CITRUN_TOOLS/citrun-wrap cc main.c
echo "ok 3 - source compiled"

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         2 Lines of source code
         1 Function definitions
         1 Return statement values
         3 Total statements
EOF
$CITRUN_TOOLS/citrun-check > check.out
check_diff 4
