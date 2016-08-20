#
# Automatically create a temporary directory and define some differencing
# functions.

set -o nounset

tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
trap "rm -rf $tmpdir" EXIT

export TEST_TOOLS="`pwd`/src";
export CITRUN_SHMPATH="$tmpdir"

cd $tmpdir
echo "ok 1 - tmp dir created"

function unlink_shm
{
	$TEST_TOOLS/citrun-dump -u $CITRUN_SHMPATH
}

#
# Run citrun-dump -t 60 times and check that each time was greater than the last
#
function test_total_execs
{
	$TEST_TOOLS/citrun-dump -t > execs.out

	sort -n execs.out > execs.sorted
	test_diff ${1} "executions strictly increasing" execs.sorted execs.out
}

#
# Differences two instrumented files. Knocks the header off of the "*.citrun"
# file.
#
function inst_diff
{
	file="${1}"
	test_num="${2}"
	test_desc="instrumented source diff"

	tail -n +24 $file.citrun > $file.inst_proc
	test_diff $test_num "$test_desc" $file.inst_good $file.inst_proc
}

#
# Differences two citrun-check outputs. Removes the "Milliseconds spent .." line
# because it always changes.
#
function check_diff
{
	test_num=${1}
	test_desc="citrun-check diff"

	grep -v "Milliseconds" check.out > check.proc
	test_diff $test_num "$test_desc" check.good check.proc
}

#
# Difference a file listing output from citrun-dump. Must be sorted first.
#
function filelist_diff
{
	test_num="${1}"
	test_desc="source file (path, length) diff"

	sort filelist.out > filelist.proc
	test_diff $test_num "$test_desc" filelist.good filelist.proc
	rm filelist.proc
}

function test_diff
{
	test_num=${1}
	test_desc="${2}"
	file_one="${3}"
	file_two="${4}"

	if diff -u $file_one $file_two > _diff.out; then
		echo ok $test_num - $test_desc
	else
		echo not ok $test_num - $test_desc
		cat _diff.out
	fi
	rm _diff.out
}
