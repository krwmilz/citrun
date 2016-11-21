#!/bin/sh -u
#
# Verify that passing a bad directory to citrun-check errors out.
#
. t/libtap.subr
. t/utils.subr
plan 1

modify_PATH

output_good="citrun-check: _nonexistent_dir_: directory does not exist"

ok_program "error on bad dir" 1 "$output_good" citrun-check _nonexistent_dir_
