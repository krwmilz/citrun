#!/bin/sh
echo 1..4

. test/utils.sh
setup

cat <<EOF > one.c
void second_func();

int
main(void)
{
	second_func();
	return 0;
}
EOF

cat <<EOF > two.c
void third_func();

void
second_func(void)
{
	third_func();
	return;
}
EOF

cat <<EOF > three.c
void
third_func(void)
{
	return;
}
EOF

cat <<EOF > Jamfile
Main program : one.c two.c three.c ;
EOF

jam && echo "ok - source compiled"

citrun-check > check.out && echo ok

cat <<EOF > check.good
Checking ..done

Summary:
         1 Log files found
         3 Source files input
         4 Calls to the instrumentation tool
         3 Forked compilers
         3 Instrument successes
         1 Application link commands

Totals:
        24 Lines of source code
        96 Lines of instrumentation header
         1 Functions called 'main'
         3 Function definitions
         1 Return statement values
         2 Call expressions
        13 Total statements
EOF

diff -u check.good check.out && echo ok