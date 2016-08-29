#!/bin/sh
#
# Verify that passing a bad directory to citrun-check errors out.
#
. test/utils.sh
plan 1

output_good="citrun-check: some_nonexistent_dir: no such directory"

ok_program "error on bad dir" 1 "$output_good" \
	$CITRUN_TOOLS/citrun-check some_nonexistent_dir
