#!/bin/sh
#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
. test/utils.sh
plan 3

diff=`which diff`
alias sed=`which sed`
alias expr=`which expr`

cat <<EOF > citrun.log.good
citrun-inst 0.0 () ''
Tool called as ''.
PATH is not set.
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
'' not in PATH.
EOF

unset PATH
ok_program "run citrun-inst as cc with no PATH" 1 "" \
	$CITRUN_TOOLS/cc -c nomatter.c

export PATH=""
ok_program "run citrun-inst as cc with empty PATH" 1 "" \
	$CITRUN_TOOLS/cc -c nomatter.c 2> /dev/null

sed	-e "s,^.*: ,,"	\
	-e "s,'.*','',"	\
	-e "s,(.*),()," \
	< citrun.log > citrun.log.proc

ok "citrun.log diff" $diff -u citrun.log.good citrun.log.proc
