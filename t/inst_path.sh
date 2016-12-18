#!/bin/sh -u
#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
. t/utils.subr
plan 2

# We need the absolute path to this faux compiler because we're killing PATH
# below.
cc=`pwd`/src/cc

# Hang onto an absolute reference to 'expr' for libtap.
alias expr=`which expr`
alias rm=`which rm`

unset PATH
output_good='citrun-inst: Error: PATH is not set.'
ok_program "run citrun-inst as cc with no PATH" 1 "$output_good" \
	$cc -c nomatter.c

export PATH=""
output_good="citrun-inst: Error: CITRUN_SHARE not in PATH."
ok_program "run citrun-inst as cc with empty PATH" 1 "$output_good" \
	$cc -c nomatter.c 2> /dev/null

# XXX: An empty citrun.log file is left behind.
rm citrun.log
