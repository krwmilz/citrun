function setup
{
	tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
	trap "rm -rf $tmpdir" EXIT
	echo "ok 1 - tmp dir created"

	export TEST_TOOLS="`pwd`/src";
	cd $tmpdir
}
