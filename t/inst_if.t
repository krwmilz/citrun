#!/bin/sh
echo 1..3

. test/utils.sh
setup

cat <<EOF > if.c
int main(int argc, char *argv[]) {
	if (argc == 1)
		return 1;
	else
		return(14);

	if ((argc = 2))
		return 5;
	else
		return(0);
}
EOF

cat <<EOF > if.c.inst_good
int main(int argc, char *argv[]) {citrun_start();++_citrun[0];
	if ((++_citrun[1], (++_citrun[1], argc == 1)))
		return (++_citrun[2], 1);
	else
		return(++_citrun[4], (14));

	if ((++_citrun[6], ((++_citrun[6], argc = 2))))
		return (++_citrun[7], 5);
	else
		return(++_citrun[9], (0));
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
        12 Lines of source code
         1 Functions called 'main'
         1 Function definitions
         2 If statements
         4 Return statement values
        21 Total statements
         2 Binary operators
EOF

$TEST_TOOLS/citrun-inst -c if.c > citrun.log
$TEST_TOOLS/citrun-check > check.out

inst_diff if.c 2
#diff -u if.c.inst_good if.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
