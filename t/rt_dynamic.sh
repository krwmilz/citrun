#
# Test that we can count an executing program as its running.
#
echo 1..2
. test/project.sh

./program 45 &
pid=$!

test_total_execs 2

kill -USR1 $pid
wait

unlink_shm
