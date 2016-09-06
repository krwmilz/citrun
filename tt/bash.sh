#!/bin/sh
#
# Check that Bash can be instrumented and still works after.
#
. tlib/package.sh
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
        30 Rewrite parse errors
       319 Rewrite successes
        28 Rewrite failures
       296 Rewritten source compile successes
        23 Rewritten source compile failures

Totals:
    165494 Lines of source code
      2693 Function definitions
      5506 If statements
       634 For loops
       309 While loops
        38 Do while loops
       138 Switch statements
      3051 Return statement values
      8243 Call expressions
    179192 Total statements
     18664 Binary operators
       549 Errors rewriting source
EOF
pkg_check

#$TEST_WRKDIST/bash > out
#echo ok 5 - bash started
#
#sleep 1
#$CITRUN_TOOLS/citrun-dump
