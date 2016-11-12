#!/bin/sh
#
# Verify the output when 0 citrun.log files are found.
#
. t/utils.subr
plan 1

output_good="No log files found."

ok_program "is no logs found message printed" 1 "$output_good" \
	$CITRUN_TOOLS/citrun-check
