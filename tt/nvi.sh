#!/bin/sh
#
# Tests that nvi works with C It Run.
#
. test/package.sh
plan 6

pkg_set "editors/nvi"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
       115 Source files used as input
         2 Application link commands
        32 Rewrite parse warnings
       115 Rewrite successes
       115 Rewritten source compile successes

Totals:
     47830 Lines of source code
       658 Function definitions
      1711 If statements
       176 For loops
        33 While loops
         6 Do while loops
       100 Switch statements
       979 Return statement values
      1646 Call expressions
     49384 Total statements
      4008 Binary operators
       353 Errors rewriting source
EOF
pkg_check

$TEST_WRKDIST/build/nvi > out

# Compiler file names are full paths so this is useless atm.
#cat <<EOF > filelist.good
#EOF
#$CITRUN_TOOLS/citrun-dump -f > filelist.out

pkg_clean
