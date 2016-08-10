#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > while.c
int
main(int argc, char *argv[])
{
	do {
		argc++;
	} while (argc != 10);
	return 0;
}
EOF

cat <<EOF > while.c.inst_good
int
main(int argc, char *argv[])
{citrun_start();++_citrun_lines[0];++_citrun_lines[1];++_citrun_lines[2];
	do {
		argc++;
	} while ((++_citrun_lines[5], argc != 10));
	return (++_citrun_lines[6], 0);
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
    9 Lines of source code
    32 Lines of instrumentation header
    1 Functions called ''
    1 Function definitions
    1 Do while loops
    1 Return statement values
    11 Total statements
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst -c while.c

diff -u while.c.inst_good while.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
