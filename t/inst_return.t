#!/bin/sh -e
echo 1..3

. test/utils.sh
setup

cat <<EOF > return.c
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF

cat <<EOF > return.c.inst_good
int foo() {++_citrun_lines[0];
	return (++_citrun_lines[1], 0);
}

int main(void) {citrun_start();++_citrun_lines[4];
	return (++_citrun_lines[5], 10);

	return (++_citrun_lines[7], 10 + 10);

	return (++_citrun_lines[9], (++_citrun_lines[9], foo()));
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
        32 Lines of instrumentation header
         1 Functions called 'main'
         2 Function definitions
         4 Return statement values
         1 Call expressions
        14 Total statements
EOF

citrun-inst -c return.c
citrun-check > check.out

diff -u return.c.inst_good return.c.citrun && echo "ok 2 - instrumented source diff"
diff -u check.good check.out && echo "ok 3 - citrun.log diff"
