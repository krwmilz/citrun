# exports CITRUN_TOOLS and sources libtap.sh.
. test/utils.sh

function pkg_set
{
	port="/usr/ports/$1"
	wrkdist=`make -C $port show=WRKDIST`

	export TEST_PORT="$port"
	export TEST_WRKDIST="$wrkdist"
}

function pkg_check_deps
{
	make -C $TEST_PORT full-build-depends > deps
	make -C $TEST_PORT full-test-depends >> deps
	sort deps | uniq > deps.uniq
	pkg_info -q > installed
	comm -2 -3 deps.uniq installed > deps_needed

	ok "build and test dependencies" diff -u /dev/null deps_needed
}

function pkg_build
{
	ok "port build" make -C $TEST_PORT PORTPATH="$CITRUN_TOOLS:\${WRKDIR}/bin:$PATH" build
}

function pkg_test
{
	#make -C $TEST_PORT PORTPATH="$CITRUN_TOOLS:\${WRKDIR}/bin:$PATH" test || true
}

function pkg_check
{
	$CITRUN_TOOLS/citrun-check -o check.out $TEST_WRKDIST
	strip_millis check.out
	ok "citrun-check output diff" diff -u check.good check.out
}

function pkg_clean
{
	ok "port clean" make -C $TEST_PORT clean=all
}

function pkg_write_tus
{
	cat <<'EOF' > tu_printer.pl
use strict;
use warnings;
use test::shm;

open(my $out, '>', 'filelist.out') or die $!;
my $shm = test::shm->new();

select $out;
$shm->print_tus();
EOF
	ok "is tu printer exit code 0" perl -I $CITRUN_TOOLS/.. tu_printer.pl
}
