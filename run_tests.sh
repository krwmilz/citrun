#!/bin/sh

make || exit 1
# make sure we have a .c extension
temp_file=$(mktemp).c

if which tput > /dev/null; then
	RED=`tput setaf 1 0 0`
	GREEN=`tput setaf 2 0 0`
	RESET=`tput sgr0`
fi

echo "starting tests"
for t in `ls tests/*.c`; do
	./instrument $t -- > $temp_file
	if ! diff -u ${t}.instrumented $temp_file; then
		echo "$t:$RED source compare failed$RESET"
		continue
	fi

	if ! gcc -o /tmp/bin $temp_file; then
		# /tmp/bin won't be created here
		echo "$t:$RED post compilation failed$RESET"
		continue
	fi

	if ! sh ${t}.sh /tmp/bin "${t}"; then
		echo "$t:$RED tests failed!$RESET"
		rm /tmp/bin
		continue
	fi
	rm /tmp/bin

	echo "$t:$GREEN ok$RESET"
done

rm $temp_file
