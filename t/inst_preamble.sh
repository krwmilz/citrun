#!/bin/sh
#
# Test that the instrumentation preamble is what we think it is.
#
. t/utils.subr
plan 3

touch preamble.c
ok "running citrun-inst" $CITRUN_TOOLS/citrun-inst -c preamble.c

cat <<EOF > preamble.c.good
#ifdef __cplusplus
extern "" {
#endif
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
static struct citrun_node _citrun = {
	1,
	"",
	"",
};
__attribute__((constructor))
static void citrun_constructor() {
	citrun_node_add(0, 0, &_citrun);
}
#ifdef __cplusplus
}
#endif
EOF

ok "remove os specific paths" sed -i -e 's/".*"/""/' preamble.c.citrun
ok "diff against known good" diff -u preamble.c.good preamble.c.citrun
