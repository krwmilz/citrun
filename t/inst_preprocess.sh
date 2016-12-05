#!/bin/sh -u
#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
. t/libtap.subr
. t/utils.subr
plan 3

modify_PATH
enter_tmpdir

echo "int main(void) { return 0; }" > prepro.c

ok "wrapping compile w/ preprocessor arg -E" citrun-wrap cc -E prepro.c
ok "wrapping compile w/ preprocessor arg -MM" citrun-wrap cc -E prepro.c

cat <<EOF > citrun.log.good
citrun-inst 0.0 ()
CITRUN_SHARE = ''
Switching argv[0] ''
PATH=''
Preprocessor argument found
citrun-inst 0.0 ()
CITRUN_SHARE = ''
Switching argv[0] ''
PATH=''
Preprocessor argument found
EOF

strip_log citrun.log
ok "citrun.log diff" diff -u citrun.log.good citrun.log.stripped
