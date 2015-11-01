#!/bin/sh

if which tput > /dev/null; then
	RED=`tput setaf 1 0 0`
	GREEN=`tput setaf 2 0 0`
	RESET=`tput sgr0`
fi

export SCV_PATH="$HOME/src/scv/compilers"
export PATH="$SCV_PATH:$PATH"

export CFLAGS="-pthread -fPIC"
export LDLIBS="-L../../runtime -lruntime -pthread"
for t in `ls tests/fibonacci/Makefile`; do
	dirname=`dirname ${t}`
	make -s -C $dirname clean

	if ! make -s -C $dirname; then
		echo "$dirname:$RED make prog failed!$RESET"
		continue
	fi

	# diff against the last known good instrumented source
	if ! make -s -C $dirname "diff"; then
		echo "$dirname:$RED source compare failed$RESET"
		continue
	fi

	# test that the instrumented binary works properly
	if ! make -s -C $dirname "test"; then
		echo "$dirname:$RED test failed!$RESET"
		continue
	fi

	make -s -C $dirname clean
	echo "$dirname:$GREEN ok$RESET"
done
