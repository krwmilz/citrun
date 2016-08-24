# exports TEST_TOOLS and puts us in a temporary directory.
. test/utils.sh

cat <<EOF > one.c
#include <err.h>
#include <stdlib.h>

long long fib(long long);
void print_output(long long);

void
usr1_sig(int signal)
{
	exit(0);
}

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2)
		errx(1, "argc != 2");

	n = atoi(argv[1]);

	print_output(fib(n));
	return 0;
}
EOF

cat <<EOF > two.c
long long
fib(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fib(n - 1) + fib(n - 2);
}
EOF

cat <<EOF > three.c
#include <stdio.h>

void
print_output(long long n)
{
	fprintf(stderr, "%lli", n);
	return;
}
EOF

cat <<EOF > Jamfile
Main program : one.c two.c three.c ;
EOF

$TEST_TOOLS/citrun-wrap jam
