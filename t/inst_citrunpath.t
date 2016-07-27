#!/bin/sh

# Test that not having CITRUN_PATH (defined at build) in PATH errors out.
#
echo 1..1
export PATH=""

src/gcc -c nomatter.c 2> /dev/null

if [ $? -eq 1 ]; then
	echo ok 1
fi
