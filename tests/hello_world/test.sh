#!/bin/sh

result="`prog`"
expected="hello, world"
if [ "$result" != "$expected" ]; then
	echo "${0}: '$result' != '$expected'"
	exit 1
fi
