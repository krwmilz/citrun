#!/bin/sh -u
#
# Test that compiling a non-existent file errors the parser out.
#
. t/libtap.subr
. t/utils.subr
plan 4

modify_PATH
enter_tmpdir

output_good="citrun-inst: stat: No such file or directory"
ok_program "is citrun-wrap failing" 1 "$output_good" citrun-wrap cc -o main main.c
ok "is citrun-check successful" citrun-check -o check.out

cat <<EOF > check.good
Summary:
         1 Source files used as input

Totals:
         0 Lines of source code
EOF

strip_millis check.out
ok "is citrun-check output identical" diff -u check.good check.out