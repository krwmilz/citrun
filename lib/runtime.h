#include <stdint.h>
struct _scv_node {
	uint64_t *lines_ptr;
	uint32_t size;
	uint32_t inst_sites;
	const char *file_name;
	struct _scv_node *next;
};
void libscv_init();
