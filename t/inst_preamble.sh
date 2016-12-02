#!/bin/sh -u
#
# Test that the instrumentation preamble is what we think it is.
#
. t/libtap.subr
. t/utils.subr
plan 3

modify_PATH
enter_tmpdir

touch preamble.c
ok "running citrun-inst" citrun-inst -c preamble.c

cat <<EOF > preamble.c.good
#ifdef __cplusplus
extern "" {
#endif
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
static struct citrun_node _citrun = {
	1,
	"",
	"",
};
__attribute__((constructor)) static void
citrun_constructor() {
	citrun_node_add(0, 0, &_citrun);
}
#ifdef __cplusplus
}
#endif
EOF

ok "remove os specific paths" sed -i -e 's/".*"/""/' preamble.c.citrun
ok "diff against known good" diff -u preamble.c.good preamble.c.citrun
