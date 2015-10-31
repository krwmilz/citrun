#!/bin/sh

if which tput > /dev/null; then
	RED=`tput setaf 1 0 0`
	GREEN=`tput setaf 2 0 0`
	RESET=`tput sgr0`
fi

export SCV_PATH="$HOME/src/scv/instrument"
export PATH="$SCV_PATH:$PATH"

export CFLAGS="-pthread"
export LDFLAGS="-L$HOME/src/scv/runtime -pthread"

export LD_LIBRARY_PATH="$HOME/src/scv/runtime"
export LDLIBS="-lruntime"
for t in `ls tests/*/prog.c`; do
	dirname=`dirname ${t}`
	make -C $dirname clean

	if ! make -C $dirname prog; then
		echo "$dirname:$RED make prog failed!$RESET"
		continue
	fi

	# diff against the last known good instrumented source
	if ! diff -u $dirname/instrumented.c $dirname/prog_inst.c; then
		echo "$dirname:$RED source compare failed$RESET"
		continue
	fi

	# test that the instrumented binary works properly
	if ! make -C $dirname "test"; then
		echo "$dirname:$RED test failed!$RESET"
		continue
	fi

	make -C $dirname clean
	echo "$dirname:$GREEN ok$RESET"
done
