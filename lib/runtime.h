#include <stdint.h>
struct _scv_node {
	uint64_t *lines_ptr;
	uint64_t size;
	const char *file_name;
	struct _scv_node *next;
};
void libscv_init();
