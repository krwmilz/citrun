#!/bin/sh -u
#
# Make sure that citrun-wrap exits with the same code as the native build.
#
. t/utils.subr
plan 1

modify_PATH

output_good="ls: asdfasdfsaf: No such file or directory"
ok_program "build command exit code" 1 "$output_good" citrun-wrap ls asdfasdfsaf
