# exports TEST_TOOLS and puts us in a temporary directory.
. test/utils.sh

# $1 is passed in by the source ('.') statements in the tests.
port="/usr/ports/${1}"
wrkdist=`make -C $port show=WRKDIST`

export TEST_PORT="$port"
export TEST_WRKDIST="$wrkdist"

function pkg_check_deps
{
	make -C $TEST_PORT full-build-depends > deps
	make -C $TEST_PORT full-test-depends >> deps
	sort deps | uniq > deps.uniq
	pkg_info -q > installed

	comm -2 -3 deps.uniq installed > deps_needed
	test_diff ${1} "build and test dependencies" /dev/null deps_needed
}

function pkg_build
{
	make -C $TEST_PORT PORTPATH="$TEST_TOOLS:\${WRKDIR}/bin:$PATH" build
	test_ret ${1} "instrumented build exit code" $?
}

function pkg_test
{
	#make -C $TEST_PORT PORTPATH="$TEST_TOOLS:\${WRKDIR}/bin:$PATH" test || true
}

function pkg_check
{
	$TEST_TOOLS/citrun-check $TEST_WRKDIST > check.out
	check_diff ${1}
}

function pkg_clean
{
	make -C $TEST_PORT clean=all
	test_ret ${1} "clean exit code" $?
}

function test_ret
{
	test_num=${1}
	test_desc="${2}"
	int=${3}

	if [ $int -eq 0 ]; then
		echo ok $test_num - $test_desc
	else
		echo not ok $test_num - $test_desc
		echo === got $int, expected 0
	fi
}
