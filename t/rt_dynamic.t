#!/bin/sh
#
# Test that we can count an executing program as its running.
#
echo 1..2
. test/project.sh

./program 45 &
pid=$!

let n=0
let lst=0
let cur=0
let bad=0
while [ $n -lt 60 ]; do
	cur=`$TEST_TOOLS/citrun-dump -t`
	[ $cur -lt $lst ] && let bad++
	let lst=cur
	let n++
done
[ $bad -eq 0 ] && echo ok 2 - program count increased 60 times


kill -USR1 $pid
wait
