#
# Test that we can count an executing program as its running.
#
echo 1..3
. test/project.sh

./program 45 &
pid=$!

$CITRUN_TOOLS/citrun-dump -t > execs.out
[ `grep -c "." execs.out` -eq 60 ] && echo ok 2 - citrun-dump -t output enough lines

sort -n execs.out > execs.sorted
test_diff 3 "executions strictly increasing" execs.sorted execs.out

kill $pid
wait
