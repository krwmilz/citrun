static unsigned int lines[512];
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

long long
fibonacci(long long n)
{
	if (lines[9] = 1, n == 0)
		return lines[10] = 1, 0;
	else if (lines[11] = 1, n == 1)
		return lines[12] = 1, 1;

	return lines[14] = 1, fibonacci(n - 1) + fibonacci(n - 2);
}

int
main(int argc, char *argv[])
{
	lines[20] = 1; long long n;
	lines[21] = 1; const char *errstr = NULL;

	if (lines[23] = 1, argc != 2) {
		printf("usage: %s <N>\n", argv[0]);
		return lines[25] = 1, 1;
	}

	n = strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr);
	if (lines[29] = 1, errstr)
		err(1, "%s", errstr);

	printf("result: %lli\n", fibonacci(n));

	return lines[34] = 1, 0;
}
