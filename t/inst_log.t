#!/bin/sh -e

echo "1..6"

tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "rm -rf $tmpdir" EXIT
echo "ok 1 - tmp dir created"

export PATH="`pwd`/src:${PATH}"
cd $tmpdir

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
Processing 5 command line arguments.
Found source file ''.
Object arg = 1, compile arg = 1
Attempting instrumentation on ''.
Adding search path ''.
Instrumentation successful.
Running native compiler on possibly modified source code.
Forked ''.
'' exited 0.
Restored ''.
Done.
citrun-inst v0.0 () called as ''.
PATH=''
Processing 4 command line arguments.
Object arg = 1, compile arg = 0
No source files to instrument.
Link detected, adding ''.
Running native compiler on possibly modified source code.
Forked ''.
'' exited 0.
Done.
EOF

diff -u citrun.log.proc citrun.log.good && echo "ok 6 - citrun.log diff"
