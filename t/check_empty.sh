#!/bin/sh
#
# Verify the output when 0 citrun.log files are found.
#
. test/utils.sh
plan 1

output_good="No log files found."

ok_program "no logs found message" 1 "$output_good" \
	$CITRUN_TOOLS/citrun-check
