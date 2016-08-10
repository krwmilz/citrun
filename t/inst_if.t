#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > if.c
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	if (argc == 1)
		return 1;
	else
		exit(14);

	if ((argc = 2))
		return 5;
	if (argc && argc + 1)
		return 0;
	else
		exit(0);
}
EOF

cat <<EOF > if.c.inst_good
#include <stdlib.h>

int
main(int argc, char *argv[])
{citrun_start();++_citrun_lines[2];++_citrun_lines[3];++_citrun_lines[4];
	if ((++_citrun_lines[5], argc == 1))
		return (++_citrun_lines[6], 1);
	else
		(++_citrun_lines[8], exit(14));

	if ((++_citrun_lines[10], (argc = 2)))
		return (++_citrun_lines[11], 5);
	if ((++_citrun_lines[12], argc && argc + 1))
		return (++_citrun_lines[13], 0);
	else
		(++_citrun_lines[15], exit(0));
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Resource directory is ''
Command line is ''.
Found source file ''.
Object arg = 0, compile arg = 1
Added clangtool argument ''.
Instrumentation of '' finished:
    18 Lines of source code
    32 Lines of instrumentation header
    1 Functions called ''
    4 Function definitions
    3 If statements
    4 Return statement values
    2 Call expressions
    173 Total statements
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst -c if.c

diff -u if.c.inst_good if.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
