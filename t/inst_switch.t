#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > switch.c
int
main(void)
{
	int i;

	switch (i) {
	case 0:
		break;
	case 1:
		break;
	}

	return 0;
}
EOF

cat <<EOF > switch.c.inst_good
int
main(void)
{citrun_start();++_citrun_lines[1];++_citrun_lines[2];++_citrun_lines[3];
	int i;

	switch ((++_citrun_lines[6], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun_lines[13], 0);
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
    15 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    1 Function declarations
    0 If statements
    0 For statements
    0 While statements
    1 Switch statements
    1 Return statement values
    0 Call expressions
    14 Total statements in source
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst switch.c

diff -u switch.c.inst_good switch.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
