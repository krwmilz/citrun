tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "rm -rf $tmpdir" EXIT
echo "ok 1 - tmp dir created"

export TEST_TOOLS="`pwd`/src";
cd $tmpdir

function inst_diff
{
	file="${1}"
	test_num="${2}"

	tail -n +33 $file.citrun > $file.inst_proc
	diff -u $file.inst_good $file.inst_proc && echo "ok $test_num - instrumented source diff"
}

function check_diff
{
	test_num="${1}"

	grep -v "Milliseconds" check.out > check.proc
	diff -u check.good check.proc && echo ok $test_num - citrun-check diff
}
