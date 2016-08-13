#!/bin/sh
#
# Check that linking object files of one citrun version with libcitrun of
# another shows a warning message.
#
echo 1..2
. test/utils.sh

cat <<EOF > main.c
#include <stddef.h>

int
main(int argc, char *argv[])
{
	citrun_node_add(0, 255, NULL);
}
EOF

/usr/bin/cc -c main.c
/usr/bin/cc -o main main.o -pthread $TEST_TOOLS/libcitrun.a

export CITRUN_SOCKET=
main 2> out

cat <<EOF > good
main: libcitrun 0.0: node with version 0.255 skipped
EOF

diff -u good out && echo ok 2
