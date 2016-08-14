#!/bin/sh
#
# Check that the advertised source file extensions work.
#
echo 1..2
. test/utils.sh

touch main.{c,cc,cxx,cpp,C}
$TEST_TOOLS/citrun-wrap cc -c main.c
$TEST_TOOLS/citrun-wrap c++ -c main.cc
$TEST_TOOLS/citrun-wrap c++ -c main.cxx
$TEST_TOOLS/citrun-wrap c++ -c main.cpp
# This one isn't supported
$TEST_TOOLS/citrun-wrap cc -c main.C

cat <<EOF > check.good
Summary:
         1 Log files found
         4 Source files input
         5 Calls to the instrumentation tool
         4 Forked compilers
         4 Instrument successes

Totals:
         4 Lines of source code
EOF

$TEST_TOOLS/citrun-check > check.out
check_diff 2
