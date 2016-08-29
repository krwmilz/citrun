#!/bin/sh

. test/utils.sh
plan 1

output_good="usage: citrun-wrap <build cmd>"
ok_program "citrun-wrap -ASD" 1 "$output_good" $CITRUN_TOOLS/citrun-wrap -ASD
