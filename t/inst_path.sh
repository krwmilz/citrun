#!/bin/sh
#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
. test/utils.sh
plan 3

# Save the PATH to restore later.
OLDPATH="${PATH}"

cat <<EOF > citrun.log.good
citrun-inst 0.0 () ''
Tool called as ''.
PATH is not set.
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
'' not in PATH.
EOF

# Hang onto an absolute reference to 'expr' for libtap.sh
alias expr=`which expr`

unset PATH
ok_program "run citrun-inst as cc with no PATH" 1 "" \
	$CITRUN_TOOLS/cc -c nomatter.c

export PATH=""
ok_program "run citrun-inst as cc with empty PATH" 1 "" \
	$CITRUN_TOOLS/cc -c nomatter.c 2> /dev/null

# Restore the path so the commands below work.
PATH="${OLDPATH}"

strip_log citrun.log
ok "citrun.log diff" diff -u citrun.log.good citrun.log.stripped
