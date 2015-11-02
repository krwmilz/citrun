#!/bin/sh

prog
if [ $? -ne 10 ]; then
	echo "${0}: basic while loops broken"
	exit 1
fi
