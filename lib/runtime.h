#include <stdint.h>
struct citrun_node {
	uint64_t		*lines_ptr;
	uint32_t		 size;
	uint32_t		 inst_sites;
	const char		*file_name;
	struct citrun_node	*next;
	uint64_t		*old_lines;
	uint64_t		*tmp_lines;
	uint32_t		*diffs;
};
void citrun_node_add(struct citrun_node *);
void citrun_start();
