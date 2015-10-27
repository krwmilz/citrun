#!/bin/sh

make || exit 1
# make sure we have a .c extension
temp_file=$(mktemp).c

if which tput > /dev/null; then
	RED=`tput setaf 1 0 0`
	GREEN=`tput setaf 2 0 0`
	RESET=`tput sgr0`
fi

for t in `ls tests/*/prog.c`; do
	./instrument $t -- > $temp_file
	dirname=`dirname ${t}`
	failed=0

	# diff against the last known good instrumented source
	if ! diff -u "$dirname/instrumented.c" $temp_file; then
		echo "$dirname/instrumented.c:$RED source compare failed$RESET"
		failed=1
	fi

	# compile the instrumented file
	if ! gcc -o /tmp/bin $temp_file; then
		# /tmp/bin won't be created here
		echo "$dirname/instrumented.c:$RED gcc compilation failed$RESET"

		rm /tmp/bin
		continue
	fi

	# test that the instrumented binary works properly
	if ! sh "$dirname/test.sh" /tmp/bin; then
		echo "$dirname/test.sh:$RED failed!$RESET"
		failed=1
	fi

	rm /tmp/bin

	if [ $failed -eq 0 ]; then
		echo "$dirname:$GREEN ok$RESET"
	fi
done

rm $temp_file
