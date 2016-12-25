#!/bin/sh -u
#
# Make sure calling citrun_wrap with arguments fails.
#
. t/utils.subr
plan 1

output_good="usage: citrun_wrap <build cmd>"
ok_program "citrun_wrap -ASD" 1 "$output_good" citrun_wrap -ASD
