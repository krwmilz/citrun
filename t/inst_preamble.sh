#!/bin/sh
#
# Test that the instrumentation preamble is what we think it is.
#
. tlib/utils.sh
plan 3

touch preamble.c
ok "running citrun-inst" $CITRUN_TOOLS/citrun-inst -c preamble.c

cat <<EOF > preamble.c.good
#ifdef __cplusplus
extern "" {
#endif
#include <limits.h>		/* PATH_MAX */
#include <stdint.h>		/* uint{64,32,8}_t */
struct citrun_node {
	uint32_t	 size;
	const char	 comp_file_path[PATH_MAX];
	const char	 abs_file_path[PATH_MAX];
	uint64_t	*data;
};
void citrun_node_add(uint8_t, uint8_t, struct citrun_node *);
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
