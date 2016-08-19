#!/bin/sh
#
# Test that the instrumentation preamble is what we think it is.
#
echo 1..2
. test/utils.sh

touch preamble.c
$TEST_TOOLS/citrun-inst -c preamble.c > citrun.log
$TEST_TOOLS/citrun-check

cat <<EOF > preamble.c.good
#ifdef __cplusplus
extern "" {
#endif
#include <stdint.h>
static const uint8_t citrun_major =	 0;
static const uint8_t citrun_minor =	 0;
struct citrun_node {
	uint32_t		 size;
	const char		*comp_file_path;
	const char		*abs_file_path;
	uint64_t		*data;
};
void citrun_node_add(uint8_t, uint8_t, struct citrun_node *);

static struct citrun_node _citrun = {
	1,
	"",
	"",
};
__attribute__((constructor))
static void citrun_constructor() {
	citrun_node_add(citrun_major, citrun_minor, &_citrun);
}
#ifdef __cplusplus
}
#endif
EOF

sed -i "s/\".*\"/\"\"/" preamble.c.citrun
diff -u preamble.c.good preamble.c.citrun && echo ok 2
