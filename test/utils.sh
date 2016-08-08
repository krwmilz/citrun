function setup
{
	tmpdir=`mktemp -d /tmp/citrun.XXXXXXXXXX`
	trap "rm -rf $tmpdir" EXIT
	echo "ok 1 - tmp dir created"

	export PATH="`pwd`/src:${PATH}"
	cd $tmpdir
}

function process_citrun_log
{
	sed	-e "s,^.*: ,,"	\
		-e "s,'.*','',"	\
		-e "s,(.*),()," \
		< citrun.log > citrun.log.proc
}
