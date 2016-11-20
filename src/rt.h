struct citrun_header {
	char			 magic[4];
	unsigned int		 major;
	unsigned int		 minor;
	unsigned int		 pids[3];
	char			 progname[1024];
	char			 cwd[1024];
};

struct citrun_node {
	unsigned int		 size;
	char			 comp_file_path[1024];
	char			 abs_file_path[1024];
	unsigned long long	*data;
};

void citrun_node_add(unsigned int, unsigned int, struct citrun_node *);
