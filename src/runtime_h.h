static const char runtime_h[] =
"#include <stdint.h>\n"
"#include <stddef.h>\n"
"struct citrun_node {\n"
"	uint64_t *lines_ptr;\n"
"	uint32_t size;\n"
"	uint32_t inst_sites;\n"
"	const char *file_name;\n"
"	struct citrun_node *next;\n"
"};\n"
"void citrun_node_add(struct citrun_node *);\n"
"void citrun_start();\n"
;
