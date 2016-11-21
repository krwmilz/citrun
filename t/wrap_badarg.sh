#!/bin/sh -u
. t/libtap.subr
. t/utils.subr
plan 1

output_good="usage: citrun-wrap <build cmd>"
ok_program "citrun-wrap -ASD" 1 "$output_good" src/citrun-wrap -ASD
