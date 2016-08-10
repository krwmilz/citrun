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

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         1 Source files input
         1 Calls to the instrumentation tool
         1 Instrument successes

Totals:
        15 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         1 Switch statements
         1 Return statement values
        14 Total statements
EOF

citrun-inst -c switch.c
citrun-check > check.out

diff -u switch.c.inst_good switch.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
