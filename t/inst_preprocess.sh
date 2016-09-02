#!/bin/sh
#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
. tlib/utils.sh
plan 3

echo "int main(void) { return 0; }" > prepro.c

ok "wrapping compile w/ preprocessor arg -E" \
	$CITRUN_TOOLS/citrun-wrap cc -E prepro.c

ok "wrapping compile w/ preprocessor arg -MM" \
	$CITRUN_TOOLS/citrun-wrap cc -E prepro.c

cat <<EOF > citrun.log.good
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
Preprocessor argument found
citrun-inst 0.0 () ''
Tool called as ''.
PATH=''
Preprocessor argument found
EOF

strip_log citrun.log
ok "citrun.log diff" diff -u citrun.log.good citrun.log.stripped
