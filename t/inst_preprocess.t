#!/bin/sh

echo 1..2

tmpfile=`mktemp`
logfile=`mktemp`

echo "int main(void) { return 0; }" > $tmpfile

export PATH="`pwd`/src:${PATH}"
gcc -x c -E $tmpfile > $logfile 2>&1

[ $? -eq 0 ] && echo ok 1
grep -q "int main(void) { return 0; }" $logfile && echo ok 2

rm $tmpfile
rm $logfile
