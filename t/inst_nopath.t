#!/bin/sh

# Test that not having PATH set errors out.
#
echo 1..2
unset PATH

tmpfile=`mktemp`
src/gcc -c nomatter.c 2> $tmpfile

if [ $? -eq 1 ]; then
	echo ok 1
fi

if grep -q "PATH must be set" $tmpfile; then
	echo ok 2
fi

rm $tmpfile
