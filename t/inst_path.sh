#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
echo 1..5

#
# This test is a little special. It unsets PATH and sets it to the empty string,
# so we must save the locations of standard utilities we use to verify things
# ahead of time.
#
grep=`which grep`
rm=`which rm`
diff=`which diff`
sed=`which sed`
cat=`which cat`

tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "$rm -rf $tmpdir" EXIT
echo "ok 1 - tmp dir created"

export TEST_TOOLS="`pwd`/src";
cd $tmpdir

# Save locations to tools because after unset PATH they are not available.
grep=`which grep`

unset PATH
$TEST_TOOLS/gcc -c nomatter.c
[ $? -eq 1 ] && echo ok 2

export PATH=""
$TEST_TOOLS/gcc -c nomatter.c 2> /dev/null
[ $? -eq 1 ] && echo ok 3

$cat <<EOF > citrun.log.good
citrun-inst 0.0 ()
Tool called as ''.
Resource directory is ''
Changing ''.
PATH is not set.
citrun-inst 0.0 ()
Tool called as ''.
Resource directory is ''
Changing ''.
PATH=''
'' not in PATH.
EOF

$sed	-e "s,^.*: ,,"	\
	-e "s,'.*','',"	\
	-e "s,(.*),()," \
	< citrun.log > citrun.log.proc \
	&& echo "ok 4 - processed citrun.log"

$diff -u citrun.log.good citrun.log.proc && echo ok 5
