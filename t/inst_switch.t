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
{citrun_start();++_citrun_lines[0];++_citrun_lines[1];++_citrun_lines[2];
	int i;

	switch ((++_citrun_lines[5], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun_lines[12], 0);
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Command line is ''.
Found source file ''.
Object arg = 0, compile arg = 1
Added clangtool argument ''.
Instrumentation of '' finished:
    15 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    1 Function definitions
    1 Switch statements
    1 Return statement values
    14 Total statements
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst -c switch.c

diff -u switch.c.inst_good switch.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
