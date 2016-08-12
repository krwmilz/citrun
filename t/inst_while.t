#!/bin/sh -e
#
# Make sure that while loop condition instrumentation works.
#
echo 1..3

. test/utils.sh
setup

cat <<EOF > while.c
int main(int argc, char *argv[]) {
	while (argc < 17)
		argc++;

	while ((argc && argv));
	return 0;
}
EOF

cat <<EOF > while.c.inst_good
int main(int argc, char *argv[]) {citrun_start();++_citrun[0];
	while ((++_citrun[1], (++_citrun[1], argc < 17)))
		argc++;

	while ((++_citrun[4], ((++_citrun[4], argc && argv))));
	return (++_citrun[5], 0);
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
         8 Lines of source code
        32 Lines of instrumentation header
         1 Functions called 'main'
         1 Function definitions
         2 While loops
         1 Return statement values
        18 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c while.c
$TEST_TOOLS/citrun-check > check.out

diff -u while.c.inst_good while.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
