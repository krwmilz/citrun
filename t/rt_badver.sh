#!/bin/sh
#
# Check that linking object files of one citrun version with libcitrun of
# another errors.
#
. test/utils.sh
plan 3

cat <<EOF > main.c
#include <stddef.h>

int
main(int argc, char *argv[])
{
	citrun_node_add(0, 255, NULL);
}
EOF

ok "compile fake node" cc -include $CITRUN_TOOLS/runtime.h -c main.c
ok "link fake node to libcitrun.a" cc -o main main.o $CITRUN_TOOLS/libcitrun.a

output_good="main: libcitrun 0.0: incompatible node version 0.255"
ok_program "running fake node" 1 "$output_good" main
