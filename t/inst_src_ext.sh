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
         5 Calls to the rewrite tool
         4 Source files used as input
         4 Rewrite successes
         4 Rewritten source compile successes

Totals:
         4 Lines of source code
EOF

$TEST_TOOLS/citrun-check > check.out
check_diff 2
