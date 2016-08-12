#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > if.c
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	if (argc == 1)
		return 1;
	else
		exit(14);

	if ((argc = 2))
		return 5;
	else
		exit(0);
}
EOF

cat <<EOF > if.c.inst_good
#include <stdlib.h>

int
main(int argc, char *argv[])
{citrun_start();++_citrun[2];++_citrun[3];++_citrun[4];
	if ((++_citrun[5], (++_citrun[5], argc == 1)))
		return (++_citrun[6], 1);
	else
		(++_citrun[8], exit(14));

	if ((++_citrun[10], ((++_citrun[10], argc = 2))))
		return (++_citrun[11], 5);
	else
		(++_citrun[13], exit(0));
}
EOF

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
        16 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         2 If statements
         2 Return statement values
         2 Call expressions
        23 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c if.c
$TEST_TOOLS/citrun-check > check.out

diff -u if.c.inst_good if.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
