#!/bin/sh -u
#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
. t/utils.subr
plan 3


echo "int main(void) { return 0; }" > prepro.c

ok "wrapping compile w/ preprocessor arg -E" citrun_wrap cc -E prepro.c
ok "wrapping compile w/ preprocessor arg -MM" citrun_wrap cc -E prepro.c

cat <<EOF > citrun.log.good
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Preprocessor argument found
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Preprocessor argument found
EOF

strip_log citrun.log
ok "citrun.log diff" diff -u citrun.log.good citrun.log.stripped
