#
# Check that linking object files of one citrun version with libcitrun of
# another errors.
#
echo 1..3
. test/utils.sh

cat <<EOF > main.c
#include <stddef.h>

int
main(int argc, char *argv[])
{
	citrun_node_add(0, 255, NULL);
}
EOF

/usr/bin/cc -include $CITRUN_TOOLS/runtime.h -c main.c
/usr/bin/cc -o main main.o $CITRUN_TOOLS/libcitrun.a

./main 2> out
[ $? -eq 1 ] && echo ok 2 - runtime errored program out

cat <<EOF > good
main: libcitrun 0.0: incompatible node version 0.255
EOF

diff -u good out && echo ok 3 - error message
