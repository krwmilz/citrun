#!/bin/sh -u
#
# Check that a raw citrun.log file is in good shape.
# citrun_check relies on this output, and citrun_check is used quite a bit.
#
. t/utils.subr
plan 3


cat <<EOF > main.c
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

ok "is compile ok" citrun_wrap cc -c main.c
ok "is link ok" citrun_wrap cc -o main main.o

strip_log citrun.log

cat <<EOF > citrun.log.good
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    22 Lines of source code
    2 Function definitions
    2 If statements
    4 Return statement values
    4 Call expressions
    58 Total statements
    6 Binary operators
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Link detected, adding '' to command line.
Modified command line is ''
No source files found on command line.
EOF

ok "log file diff" diff -u citrun.log.good citrun.log.stripped
