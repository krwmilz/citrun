#!/bin/sh

result="`/tmp/bin 10`"
if [ "$result" != "result: 55" ]; then
	echo "${2}.sh: $result != \"result: 55\""
	exit 1
fi

result="`/tmp/bin 20`"
expected="result: 6765"
if [ "$result" != "$expected" ]; then
	echo "${2}.sh: '$result' != '$expected'"
	exit 1
fi
