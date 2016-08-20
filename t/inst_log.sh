#
# Check that a raw citrun.log file is in good shape.
# citrun-check relies on this output, and citrun-check is used quite a bit.
#
echo 1..6
. test/utils.sh

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

$TEST_TOOLS/citrun-wrap jam && echo "ok 4 - source compiled"

sed	-e "s,^.*: ,,"	\
	-e "s,'.*','',"	\
	-e "s,(.*),()," \
	-e "/Milliseconds/d" \
	< citrun.log > citrun.log.proc \
	&& echo "ok 5 - processed citrun.log"

cat <<EOF > citrun.log.good
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
Found source file ''.
Command line is ''.
Added clangtool argument ''.
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
Forked ''.
'' exited 0.
Rewritten source compile successful.
Restored ''.
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
Command line is ''.
Link detected, adding '' to command line.
No source files found on command line.
EOF

diff -u citrun.log.good citrun.log.proc && echo "ok 6 - citrun.log diff"
