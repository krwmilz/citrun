static const char runtime_h[] =
"#include <stdint.h>\n"
"struct _scv_node {\n"
"	uint64_t *lines_ptr;\n"
"	uint32_t size;\n"
"	uint32_t inst_sites;\n"
"	const char *file_name;\n"
"	struct _scv_node *next;\n"
"};\n"
"void libscv_init();\n"
;
