#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

long long
fibonacci(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int
main(int argc, char *argv[])
{
	long long n;
	const char *errstr = NULL;

	if (argc != 2) {
		printf("usage: %s <N>\n", argv[0]);
		return 1;
	}

	n = strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr);
	if (errstr)
		err(1, "%s", errstr);

	printf("result: %lli\n", fibonacci(n));

	return 0;
}
