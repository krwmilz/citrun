#!/bin/sh -e

echo "1..5"

tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "rm -rf $tmpdir" EXIT
echo "ok 1 - tmp dir created"

export PATH="`pwd`/src:${PATH}"
cd $tmpdir

cat <<EOF > main.c
int
main(void)
{
	return 0;
}
EOF
echo "ok 2 - source files wrote"

# Check that a command as simple as this works.
#
cc main.c
echo "ok 3 - source compiled"

citrun-check | sed -e "s,'.*',''," > citrun-check.txt
echo "ok 4 - processed citrun.log"

cat <<EOF > citrun-check.txt.good
Checking ''.
       1  Log files found
       1  Calls to the instrumentation tool
       1  Forked compilers
       1  Instrumentation successes
       1  Application link commands
EOF

diff -u citrun-check.txt.good citrun-check.txt
echo "ok 5 - citrun.log diff"
