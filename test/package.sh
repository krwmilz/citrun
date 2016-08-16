# exports TEST_TOOLS and puts us in a temporary directory.
. test/utils.sh

export CITRUN_SOCKET="test.socket";

function pkg_instrument
{
	port="/usr/ports/${1}"
	wrkdist=`make -C $port show=WRKDIST`

	export TEST_PORT="$port"
	export TEST_WRKDIST="$wrkdist"

	make -C $port full-build-depends > deps
	make -C $port full-test-depends >> deps
	sort deps | uniq > deps.uniq
	pkg_info -q > installed

	comm -2 -3 deps.uniq installed > deps_needed
	diff -u /dev/null deps_needed

	echo ok 2 - build and test dependencies installed

	make -C $port clean=all
	make -C $port PORTPATH="$TEST_TOOLS:\${WRKDIR}/bin:$PATH" build
	echo ok 3 - instrumented build
	#make -C $port PORTPATH="$TEST_TOOLS:\${WRKDIR}/bin:$PATH" test || true
}

function pkg_check
{
	$TEST_TOOLS/citrun-check $TEST_WRKDIST > check.out
	check_diff ${1}
}

function pkg_clean
{
	make -C $TEST_PORT clean=all
}
