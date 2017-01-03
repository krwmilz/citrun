static const unsigned int citrun_major = 0;
static const unsigned int citrun_minor = 0;

struct citrun_header {
	char			 magic[4];
	unsigned int		 major;
	unsigned int		 minor;
	unsigned int		 pids[3];
	unsigned int		 units;
	unsigned int		 loc;
	unsigned int		 exited;
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
