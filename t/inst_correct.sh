#
# Check that a simple program can execute successfully with instrumentation.
#
echo 1..5
. test/utils.sh

cat <<EOF > fib.c
#include <stdlib.h>

int fibonacci(int n) {
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(int argc, char *argv[]) {
	int n;

	if (argc != 2)
		return -1;

	n = atoi(argv[1]);
	return fibonacci(n);
}
EOF

cat <<EOF > check.good
Summary:
         1 Source files used as input
         1 Application link commands
         1 Rewrite successes
         1 Rewritten source compile successes

Totals:
        21 Lines of source code
         2 Function definitions
         3 If statements
         5 Return statement values
         4 Call expressions
        58 Total statements
         7 Binary operators
EOF

$TEST_TOOLS/citrun-wrap cc -o fib fib.c
$TEST_TOOLS/citrun-check > check.out

check_diff 2

./fib
[ $? -eq 255 ] && echo ok

./fib 10 # = 55
[ $? -eq 55 ] && echo ok

./fib 12 # = 6765
[ $? -eq 144 ] && echo ok

unlink_shm
