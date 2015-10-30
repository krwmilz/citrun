unsigned int lines[512];
int size = 512;
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

long long
fibonacci(long long n)
{
	if ((lines[9] = 1, n == 0))
		return (lines[10] = 1, 0);
	else if ((lines[11] = 1, n == 1))
		return (lines[12] = 1, 1);

	return (lines[14] = 1, (lines[14] = 1, fibonacci(n - 1)) + (lines[14] = 1, fibonacci(n - 2)));
}

int
main(int argc, char *argv[])
{
	long long n;
	const char *errstr = NULL;

	if ((lines[23] = 1, argc != 2)) {
		(lines[24] = 1, printf("usage: %s <N>\n", argv[0]));
		return (lines[25] = 1, 1);
	}

	n = (lines[28] = 1, strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr));
	if ((lines[29] = 1, errstr))
		(lines[30] = 1, err(1, "%s", errstr));

	(lines[32] = 1, printf("result: %lli\n", (lines[32] = 1, fibonacci(n))));

	return (lines[34] = 1, 0);
}
