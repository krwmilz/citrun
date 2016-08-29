. test/libtap.sh

set -o nounset
export CITRUN_TOOLS="`pwd`/src"

function remove_preamble
{
	file="${1}"
	tail -n +24 $file.citrun > $file.citrun_nohdr
}

function strip_log
{
	sed	-e "s,^.*: ,,"	\
		-e "s,'.*','',"	\
		-e "s,(.*),()," \
		-e "/Milliseconds/d" \
		< ${1} > ${1}.stripped
}
