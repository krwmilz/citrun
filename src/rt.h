#include <limits.h>		/* PATH_MAX */
#include <stdint.h>		/* uint{64,32,8}_t */

struct citrun_header {
	char		 magic[6];
	uint8_t		 major;
	uint8_t		 minor;
	uint32_t	 pids[3];
	char		 progname[PATH_MAX];
	char		 cwd[PATH_MAX];
};

struct citrun_node {
	uint32_t	 size;
	const char	 comp_file_path[PATH_MAX];
	const char	 abs_file_path[PATH_MAX];
	uint64_t	*data;
};

void citrun_node_add(uint8_t, uint8_t, struct citrun_node *);
