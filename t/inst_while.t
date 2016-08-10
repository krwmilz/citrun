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
{citrun_start();++_citrun_lines[0];++_citrun_lines[1];++_citrun_lines[2];
	while ((++_citrun_lines[3], argc < 17))
		argc++;

	while ((++_citrun_lines[6], (argc && argv)));
	return (++_citrun_lines[7], 0);
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
        10 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         2 While loops
         1 Return statement values
        18 Total statements
EOF

citrun-inst -c while.c
citrun-check > check.out

diff -u while.c.inst_good while.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
