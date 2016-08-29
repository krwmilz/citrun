#
# Test that the shared memory header is what we expect.
#
echo 1..2
. test/project.sh

env

./program 1 &
pid=$!
wait

cat <<EOF  | sed -e "s,%PID%,$pid," -e "s,%CWD%,`pwd -P`," > dump.good
Found dead program with PID '%PID%'
  Runtime version: 0.0
  Translation units: 3
  Lines of code: 46
  Working directory: '%CWD%'
EOF

$CITRUN_TOOLS/citrun-dump > dump.out
test_diff 2 "citrun-dump diff" dump.good dump.out
