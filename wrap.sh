
dirname=`dirname $0`
export CITRUN_PATH="`cd $dirname && pwd`/"
export PATH="${CITRUN_PATH}compilers:$PATH"
exec $@
