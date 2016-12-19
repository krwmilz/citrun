#!/bin/sh -u
#
# Verify the output when 0 citrun.log files are found.
#
. t/utils.subr
plan 1

enter_tmpdir

output_good="Summary:
         0 Source files used as input"
ok_program "is no logs found message printed" 123 "$output_good" citrun-check .
