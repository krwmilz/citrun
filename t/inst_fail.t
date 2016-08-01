#!/bin/sh

echo 1..2

tmpfile=`mktemp`
logfile=`mktemp`

echo "int main(void) { return 0; " > $tmpfile.c

export PATH="`pwd`/src:${PATH}"
gcc -c $tmpfile.c 2> $logfile

[ $? -eq 1 ] && echo ok 1
grep -q "error: expected" $logfile && echo ok 2

rm $tmpfile.c
rm $tmpfile
rm $logfile
