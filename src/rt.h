#define CITRUN_PATH_MAX		1024

struct citrun_header {
	char			 magic[4];
	unsigned int		 major;
	unsigned int		 minor;
	unsigned int		 pids[3];
	char			 progname[CITRUN_PATH_MAX];
	char			 cwd[CITRUN_PATH_MAX];
};

struct citrun_node {
	unsigned int		 size;
	const char		 comp_file_path[CITRUN_PATH_MAX];
	const char		 abs_file_path[CITRUN_PATH_MAX];
	unsigned long long	*data;
};

void citrun_node_add(unsigned int, unsigned int, struct citrun_node *);
