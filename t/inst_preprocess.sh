#!/bin/sh -u
#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
. t/utils.subr
plan 3


echo "int main(void) { return 0; }" > prepro.c

ok "is instrumented compile argument -E handled" cc -E prepro.c
ok "is instrumented compile argument  -MM handled" cc -MM prepro.c

cat <<EOF > citrun.log.good
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Preprocessor argument -E found
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
PATH=''
Preprocessor argument -MM found
EOF

strip_log citrun.log
ok "citrun.log diff" diff -u citrun.log.good citrun.log.stripped
