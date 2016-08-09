#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > for.c
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	for (;;);

	for (argc = 0; argc < 10; argc++)
		argv++;
}
EOF

cat <<EOF > for.c.inst_good
#include <stdlib.h>

int
main(int argc, char *argv[])
{citrun_start();++_citrun_lines[2];++_citrun_lines[3];++_citrun_lines[4];
	for (;;);

	for (argc = 0; (++_citrun_lines[7], argc < 10); argc++)
		argv++;
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Command line is ''.
Found source file ''.
Object arg = 0, compile arg = 1
Added clangtool argument ''.
Instrumentation of '' finished:
    11 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    4 Function definitions
    1 For statements
    1 Return statement values
    155 Total statements
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst -c for.c

diff -u for.c.inst_good for.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
