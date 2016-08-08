#!/bin/sh -e
echo 1..6

. test/utils.sh
setup

cat <<EOF > source_0.c
#include <stdlib.h>

long long
fibonacci(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int
main(int argc, char *argv[])
{
	long long n;

	n = atoi(argv[1]);
	return fibonacci(n);
}
EOF
echo "ok 2 - source file wrote"

cat <<EOF > Jamfile
Main program : source_0.c ;
EOF
echo "ok 3 - Jamfile wrote"

jam && echo "ok 4 - source compiled"

sed	-e "s,^.*: ,,"	\
	-e "s,'.*','',"	\
	-e "s,(.*),()," \
	< citrun.log > citrun.log.proc \
	&& echo "ok 5 - processed citrun.log"

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
PATH=''
Command line is ''.
Found source file ''.
Object arg = 1, compile arg = 1
Added clangtool argument ''.
Instrumentation of '' finished:
    22 Lines of source code
    30 Lines of instrumentation header
    1 Functions called ''
    5 Function declarations
    2 If statements
    0 For statements
    0 While statements
    0 Switch statements
    5 Return statement values
    4 Call expressions
    198 Total statements in source
Modified source written successfully.
Instrumentation successful.
Running native compiler on modified source code.
Forked ''.
'' exited 0.
Restored ''.

citrun-inst v0.0 () called as ''.
PATH=''
Command line is ''.
Object arg = 1, compile arg = 0
Link detected, adding '' to command line.
No source files found. Executing command line.
EOF

diff -u citrun.log.good citrun.log.proc && echo "ok 6 - citrun.log diff"
