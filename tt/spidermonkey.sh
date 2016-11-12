#!/bin/sh
#
# Try and instrument spidermonkey.
#
. tt/package.subr
plan 6

pkg_set "devel/spidermonkey"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
       366 Source files used as input
        64 Application link commands
     58239 Rewrite parse warnings
        26 Rewrite parse errors
       346 Rewrite successes
        20 Rewrite failures
       278 Rewritten source compile successes
        68 Rewritten source compile failures

Totals:
    851729 Lines of source code
      9294 Function definitions
     11463 If statements
      1178 For loops
       298 While loops
        37 Do while loops
       262 Switch statements
     10675 Return statement values
     42390 Call expressions
    437974 Total statements
     13491 Binary operators
      1888 Errors rewriting source
EOF
pkg_check

pkg_clean
