#
# Test that building Mutt works.
#
echo 1..5
. test/package.sh "mail/mutt"

pkg_check_deps 2
pkg_clean 3
pkg_build 4

cat <<EOF > check.good
Summary:
       262 Calls to the rewrite tool
       218 Source files used as input
        73 Application link commands
       339 Rewrite parse warnings
        10 Rewrite parse errors
       209 Rewrite successes
         9 Rewrite failures
       194 Rewritten source compile successes
        15 Rewritten source compile failues

Totals:
     94664 Lines of source code
      1711 Function definitions
      4895 If statements
       484 For loops
       326 While loops
        37 Do while loops
       104 Switch statements
      1956 Return statement values
      6894 Call expressions
    153793 Total statements
     12082 Binary operators
       558 Errors rewriting source
EOF
pkg_check 5
