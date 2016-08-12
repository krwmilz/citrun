function setup
{
	tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
	trap "rm -rf $tmpdir" EXIT
	echo "ok 1 - tmp dir created"

	export CITRUN_TOOLS="`pwd`/src";
	export PATH="${CITRUN_TOOLS}:${PATH}"
	cd $tmpdir
}
