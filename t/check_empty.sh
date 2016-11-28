#!/bin/sh -u
#
# Verify the output when 0 citrun.log files are found.
#
. t/libtap.subr
. t/utils.subr
plan 1

modify_PATH
enter_tmpdir

output_good="Summary:
         0 citrun.log files processed"
ok_program "is no logs found message printed" 0 "$output_good" citrun-check .
