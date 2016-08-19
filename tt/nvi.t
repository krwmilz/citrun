#!/bin/sh -e
#
# Tests that nvi works with C It Run.
#
echo 1..4
. test/package.sh

pkg_instrument "editors/nvi"

cat <<EOF > check.good
Summary:
       116 Calls to the rewrite tool
       115 Source files used as input
         2 Application link commands
        32 Rewrite parse warnings
       115 Rewrite successes
       115 Rewritten source compile successes

Totals:
     47830 Lines of source code
         2 Functions called 'main'
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
pkg_check 4

# $TEST_WRKDIST/build/nvi

pkg_clean
