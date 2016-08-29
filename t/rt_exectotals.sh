#
# Test that we can count an executing program as its running.
#
. test/utils.sh
plan 4

cat <<EOF > check_totals.cc
#include "src/process_dir.h"
#include "test/basic.h"

#include <iostream>

int
main(void)
{
	ProcessDir pdir;
	pdir.scan();

	ProcessFile f = pdir.m_procfiles[0];

	for (int i = 0; i < 60; i++)
		std::cout << f.total_execs() << std::endl;
}
EOF

ok "tap program compile" clang++ -std=c++11 -c check_totals.cc \
	-I$CITRUN_TOOLS/..
ok "tap program link" clang++ -o tap_program check_totals.o \
	$CITRUN_TOOLS/utils.a $CITRUN_TOOLS/../test/tap.a

program 45 &
pid=$!

ok "tap program run" tap_program

kill $pid
wait
