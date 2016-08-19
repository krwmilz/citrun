#!/bin/sh
#
# Test that the source files the runtime passed us and we loaded are identical
# to the original source files on disk.
#
echo 1..4
. test/project.sh

./program 45 &
pid=$!

$TEST_TOOLS/citrun-dump -s one.c > one.c.runtime
$TEST_TOOLS/citrun-dump -s two.c > two.c.runtime
$TEST_TOOLS/citrun-dump -s three.c > three.c.runtime

kill -USR1 $pid
wait

# Bug in parsing source line by line in c++
echo >> one.c
echo >> two.c
echo >> three.c

test_diff 2 "one.c diff runtime and disk" one.c one.c.runtime
test_diff 3 "two.c diff runtime and disk" two.c two.c.runtime
test_diff 4 "three.c diff runtime and disk" three.c three.c.runtime
