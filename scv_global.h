#include <stdint.h>

struct scv_node {
	/* long long in C99 is also guaranteed to be 64 bits */
	uint64_t *lines_ptr;
	uint64_t size;
	const char *file_name;
	struct scv_node *next;
};
