#!/bin/sh -u
#
# Check that linking object files of one citrun version with libcitrun.a of
# another errors.
#
. t/utils.subr
plan 2


cat <<EOF > main.c
#include <stddef.h>
struct citrun_node;
void citrun_node_add(unsigned int, unsigned int, struct citrun_node *);

int
main(int argc, char *argv[])
{
	citrun_node_add(0, 255, NULL);
}
EOF

ok "is compiled" cc -o main main.c

output_good="main: libcitrun-0.0: incompatible version 0.255, try cleaning and rebuilding your project"
ok_program "running fake node" 1 "$output_good" ./main
