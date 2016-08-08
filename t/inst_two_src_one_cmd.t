#!/bin/sh -e

echo "1..5"

tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "rm -rf $tmpdir" EXIT
echo "ok 1 - tmp dir created"

export PATH="`pwd`/src:${PATH}"
cd $tmpdir

cat <<EOF > main.c
int
main(void)
{
	return 0;
}
EOF

cat <<EOF > other.c
int
other(void)
{
	return 0;
}
EOF
echo "ok 2 - source files wrote"

cc -o main main.c other.c
echo "ok 3 - source compiled"

sed	-e "s,^.*: ,,"	\
	-e "s,'.*','',"	\
	-e "s,(.*),()," \
	< citrun.log > citrun.log.proc
echo "ok 4 - processed citrun.log"

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
PATH=''
Command line is ''.
Found source file ''.
Found source file ''.
Object arg = 1, compile arg = 0
Link detected, adding '' to command line.
Added clangtool argument ''.
Instrumentation of '' finished:
    6 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    1 Function declarations
    0 If statements
    0 For statements
    0 While statements
    0 Switch statements
    1 Return statement values
    0 Call expressions
    3 Total statements in source
Modified source written successfully.
Instrumentation of '' finished:
    6 Lines of source code
    30 Lines of instrumentation header
    0 Functions called ''
    1 Function declarations
    0 If statements
    0 For statements
    0 While statements
    0 Switch statements
    1 Return statement values
    0 Call expressions
    3 Total statements in source
Modified source written successfully.
Instrumentation successful.
Running native compiler on modified source code.
Forked ''.
'' exited 0.
Restored ''.
Restored ''.
EOF

diff -u citrun.log.good citrun.log.proc
echo "ok 5 - citrun.log diff"
