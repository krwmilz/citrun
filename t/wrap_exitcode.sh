#!/bin/sh
#
# Make sure that citrun-wrap exits with the same code as the native build.
#
. test/utils.sh
plan 1

output_good="ls: asdfasdfsaf: No such file or directory"
ok_program "build command exit code" 1 "$output_good" \
	$CITRUN_TOOLS/citrun-wrap ls asdfasdfsaf
