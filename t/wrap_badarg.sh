#!/bin/sh -u
#
# Make sure calling citrun-wrap with arguments fails.
#
. t/utils.subr
plan 1

output_good="usage: citrun-wrap <build cmd>"
ok_program "citrun-wrap -ASD" 1 "$output_good" citrun-wrap -ASD
