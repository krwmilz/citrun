#!/bin/sh
#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
. t/utils.subr
plan 2

OLDPATH=${PATH}

# Hang onto an absolute reference to 'expr' for libtap.sh
alias expr=`which expr`

unset PATH
output_good='citrun-inst: Error: PATH is not set.'
ok_program "run citrun-inst as cc with no PATH" 1 "$output_good" \
	$CITRUN_TOOLS/cc -c nomatter.c

export PATH=""
output_good="citrun-inst: Error: CITRUN_SHARE not in PATH."
ok_program "run citrun-inst as cc with empty PATH" 1 "$output_good" \
	$CITRUN_TOOLS/cc -c nomatter.c 2> /dev/null

PATH=${OLDPATH}
