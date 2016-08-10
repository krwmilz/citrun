#!/bin/sh
echo 1..5

. test/utils.sh
setup

cat <<EOF > fib.c
#include <stdlib.h>

int
fibonacci(int n)
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
	int n;

	if (argc != 2)
		return -1;

	n = atoi(argv[1]);
	return fibonacci(n);
}
EOF

cat <<EOF > citrun.log.good

citrun-inst v0.0 () called as ''.
Resource directory is ''
PATH=''
Command line is ''.
Found source file ''.
Object arg = 1, compile arg = 0
Link detected, adding '' to command line.
Added clangtool argument ''.
Instrumentation of '' finished:
    25 Lines of source code
    32 Lines of instrumentation header
    1 Functions called ''
    5 Function definitions
    3 If statements
    6 Return statement values
    4 Call expressions
    198 Total statements
Modified source written successfully.
Instrumentation successful.
Running native compiler on modified source code.
Forked ''.
'' exited 0.
Restored ''.
EOF

cc -o fib fib.c

process_citrun_log
diff -u citrun.log.good citrun.log.proc && echo "ok 2 citrun.log diff"

export CITRUN_SOCKET=
./fib
[ $? -eq 255 ] && echo ok

./fib 10 # = 55
[ $? -eq 55 ] && echo ok

./fib 12 # = 6765
[ $? -eq 144 ] && echo ok
