#!/bin/sh -u
#
# Verify that passing a bad directory to citrun-check errors out.
#
. t/libtap.subr
. t/utils.subr
plan 1

modify_PATH

output_good="find: _nonexistent_dir_: No such file or directory
Summary:
         0 Source files used as input"
ok_program "error on bad dir" 123 "$output_good" citrun-check _nonexistent_dir_
