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
{citrun_start();++_citrun[0];++_citrun[1];++_citrun[2];
	do {
		argc++;
	} while ((++_citrun[5], (++_citrun[5], argc != 10)));
	return (++_citrun[6], 0);
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
         9 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         1 Do while loops
         1 Return statement values
        11 Total statements
         1 Binary operators
EOF

citrun-inst -c while.c
citrun-check > check.out

diff -u while.c.inst_good while.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
