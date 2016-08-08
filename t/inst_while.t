#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > while.c
int
main(int argc, char *argv[])
{
	while (argc < 17)
		argc++;

	while ((argc && argv));
	return 0;
}
EOF

cat <<EOF > while.c.inst_good
int
main(int argc, char *argv[])
{citrun_start();++_citrun_lines[1];++_citrun_lines[2];++_citrun_lines[3];
	while ((++_citrun_lines[4], argc < 17))
		argc++;

	while ((++_citrun_lines[7], (argc && argv)));
	return (++_citrun_lines[8], 0);
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Command line is ''.
Found source file ''.
Object arg = 0, compile arg = 1
Added clangtool argument ''.
Instrumentation of '' finished:
    10 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    1 Function declarations
    0 If statements
    0 For statements
    2 While statements
    0 Switch statements
    1 Return statement values
    0 Call expressions
    18 Total statements in source
Writing modified source to ''.
Modified source written successfully.
Instrumentation successful.
EOF

citrun-inst -c while.c

diff -u while.c.inst_good while.c.citrun && echo "ok 2 - instrumented source diff"

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 3 - citrun.log diff"
