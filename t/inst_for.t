#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

echo "ok 1 - tmp dir created"

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
{citrun_start();++_citrun_lines[3];++_citrun_lines[4];++_citrun_lines[5];
	for (;;);

	for (argc = 0; (++_citrun_lines[8], argc < 10); argc++)
		argv++;
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Command line is ''.
Found source file ''.
Object arg = 0, compile arg = 0
Link detected, adding '' to command line.
Added clangtool argument ''.
Instrumentation of '' finished:
    11 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    4 Function declarations
    0 If statements
    1 For statements
    0 While statements
    0 Switch statements
    1 Return statement values
    0 Call expressions
    155 Total statements in source
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst for.c

diff -u for.c.inst_good for.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
