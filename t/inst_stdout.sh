#
# Simple program that prints output.
#
echo 1..3
. test/utils.sh

cat <<EOF > hello.c
#include <stdio.h>

int main(void) {
	printf("hello, world!");
	return 0;
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
         7 Lines of source code
         1 Function definitions
         1 Return statement values
         1 Call expressions
         9 Total statements
EOF

$TEST_TOOLS/citrun-wrap cc -o hello hello.c
$TEST_TOOLS/citrun-check > check.out

[ "`./hello`" = "hello, world!" ] && echo ok program prints

check_diff 3
