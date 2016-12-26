#!/bin/sh -u
#
# Test that wrapping the 'make' build system produces instrumented binaries.
#
. t/utils.subr
plan 12

empty_main
cp main.c main1.c
cp main.c main2.c
cp main.c main3.c
cp main.c main4.c

cat <<EOF > Makefile
all: program1 program2 program3 program4

program1: main1.o
	cc -o program1 main1.o
program2: main2.o
	cc -o program2 main2.o
program3: main3.o
	cc -o program3 main3.o
program4: main4.o
	cc -o program4 main4.o
EOF

ok "is instrumented make -j4 successful" make -j4
ok "is citrun_check successful" citrun_check -o check.out

cat <<EOF > check.good
Summary:
         4 Source files used as input
         4 Application link commands
         4 Rewrite successes
         4 Rewritten source compile successes

Totals:
        24 Lines of source code
         4 Function definitions
         4 Return statement values
        12 Total statements
EOF

strip_millis check.out
ok "is citrun_check output identical" diff -u check.good check.out

for i in 1 2 3 4; do
	ok "is program$i execution successful" ./program$i
	ok "is program$i runtime memory file created" test -f procdir/program${i}_*
done
