#!/bin/sh -u
#
# Test that compiling a non-existent file errors the parser out.
#
. t/utils.subr
plan 4


output_good="citrun_inst: stat: No such file or directory"
ok_program "is citrun_wrap failing" 1 "$output_good" citrun_wrap cc -o main main.c
ok "is citrun_check successful" citrun_check -o check.out

cat <<EOF > check.good
Summary:
         1 Source files used as input

Totals:
         0 Lines of source code
EOF

strip_millis check.out
ok "is citrun_check output identical" diff -u check.good check.out
