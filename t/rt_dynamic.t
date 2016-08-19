#!/bin/sh
#
# Test that we can count an executing program as its running.
#
echo 1..61
. test/project.sh

./program 45 &
pid=$!

let n=0
let lst=0
let cur=0
while [ $n -lt 60 ]; do
	cur=`$TEST_TOOLS/citrun-dump -t`
	[ $cur -gt $lst ] && echo ok
	let lst=cur
	let n++
done

kill -USR1 $pid
wait
