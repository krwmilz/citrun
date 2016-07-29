#!/bin/sh

# Test that not having PATH set errors out.
#
echo 1..2
tmpfile=`mktemp`

# Save locations to tools because after unset PATH they are not available.
grep=`which grep`
rm=`which rm`

unset PATH
src/gcc -c nomatter.c 2> $tmpfile

[ $? -eq 1 ] && echo ok 1
$grep -q "PATH must be set" $tmpfile && echo ok 2

$rm $tmpfile
