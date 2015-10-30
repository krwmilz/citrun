unsigned int lines[77];
int size = 77;
#include <stdio.h>

int
main(void)
{
	(lines[6] = 1, printf("hello, world\n"));
	return (lines[7] = 1, 0);
}
