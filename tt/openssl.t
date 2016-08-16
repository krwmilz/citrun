#!/bin/sh -e
#
# Instrument openssl, run its testsuite, check the logs and do a quick runtime
# sanity test on it.
#
echo 1..5
. test/package.sh

pkg_instrument "security/openssl"

cat <<EOF > check.good
Summary:
       868 Calls to the rewrite tool
       752 Source files used as input
        58 Application link commands
       752 Rewrite parse warnings
       752 Rewrite successes
       752 Rewritten source compile successes

Totals:
    322027 Lines of source code
        43 Functions called 'main'
      6722 Function definitions
     15969 If statements
       877 For loops
       277 While loops
        47 Do while loops
       275 Switch statements
      7438 Return statement values
     18751 Call expressions
    418826 Total statements
     27553 Binary operators
      2912 Errors rewriting source
EOF
pkg_check 4


export LD_LIBRARY_PATH="$TEST_WRKDIST";
$TEST_WRKDIST/apps/openssl &

$TEST_TOOLS/citrun-dump

pkg_clean
