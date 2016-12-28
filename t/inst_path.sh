#!/bin/sh -u
#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
. t/utils.subr
plan 2

# Save PATH to restore it later. ok_program needs 'expr' to count too.
OLDPATH="${PATH}"
alias expr=`which expr`

unset PATH
output_good='citrun_inst: Error: PATH is not set.'
ok_program "run citrun_inst as cc with no PATH" 1 "$output_good" \
	$treedir/src/cc -c nomatter.c

export PATH=""
output_good="citrun_inst: Error: CITRUN_SHARE not in PATH."
ok_program "run citrun_inst as cc with empty PATH" 1 "$output_good" \
	$treedir/src/cc -c nomatter.c 2> /dev/null

export PATH="${OLDPATH}"
