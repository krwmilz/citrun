struct scv_node {
	unsigned int *lines_ptr;
	unsigned int size;
	const char *file_name;
	struct scv_node *next;
	/* unsigned int not_end; */
};
