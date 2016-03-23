static const char *runtime_h =
"#include <stdint.h>\n"
"struct _scv_node {\n"
"	uint64_t *lines_ptr;\n"
"	uint64_t size;\n"
"	const char *file_name;\n"
"	struct _scv_node *next;\n"
"};\n"
"void libscv_init();\n"
;
