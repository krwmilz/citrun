#include <stdint.h>
static uint8_t citrun_major =	0;
static uint8_t citrun_minor =	0;
struct citrun_node {
	uint64_t		*lines_ptr;
	uint32_t		 size;
	const char		*file_name;
	struct citrun_node	*next;
	uint64_t		*old_lines;
	uint32_t		*diffs;
};
void citrun_node_add(uint8_t, uint8_t, struct citrun_node *);
void citrun_start();
