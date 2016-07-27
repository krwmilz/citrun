#!/bin/sh

echo 1..2

tmpfile=`mktemp`.c
logfile=`mktemp`

echo "int main(void) { return 0; " > $tmpfile

export PATH="`pwd`/src:${PATH}"
gcc -c $tmpfile 2> $logfile

if [ $? -eq 1 ]; then
	echo ok 1
fi

if grep -q "Instrumentation failed!" $logfile; then
	echo ok 2
fi

rm $tmpfile
rm $logfile
