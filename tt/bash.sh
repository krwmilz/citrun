#!/bin/sh
#
# Check that Bash can be instrumented and still works after.
#
. test/package.sh
plan 5

pkg_set "shells/bash"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
       347 Source files used as input
        96 Application link commands
       190 Rewrite parse warnings
        31 Rewrite parse errors
       318 Rewrite successes
        29 Rewrite failures
       295 Rewritten source compile successes
        23 Rewritten source compile failures

Totals:
    165512 Lines of source code
      2698 Function definitions
      5519 If statements
       635 For loops
       309 While loops
        38 Do while loops
       138 Switch statements
      3057 Return statement values
      8254 Call expressions
    179490 Total statements
     18704 Binary operators
       549 Errors rewriting source
EOF
pkg_check

#$TEST_WRKDIST/bash > out
#echo ok 5 - bash started
#
#sleep 1
#$CITRUN_TOOLS/citrun-dump
