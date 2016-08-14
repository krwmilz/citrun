use strict;
use warnings;
use Expect;
use Test::More tests => 1 ;
use test::package;
use test::viewer;

my $package = test::package->new("devel/spidermonkey");

open( my $fh, ">", "check.good" );
print $fh <<EOF;
Summary:
         6 Log files found
       438 Calls to the rewrite tool
       366 Source files used as input
        64 Application link commands
     58239 Rewrite parse warnings
        26 Rewrite parse errors
       346 Rewrite successes
        19 Rewrite failures (False Positive)
         1 Rewrite failures (True Positive!)
       281 Rewritten source compile successes
        15 Rewritten source compile failures (False Positive)
        50 Rewritten source compile failures (True Positive!)

Totals:
    851729 Lines of source code
        92 Functions called 'main'
      9294 Function definitions
     11463 If statements
      1178 For loops
       298 While loops
        37 Do while loops
       262 Switch statements
     10479 Return statement values
     42390 Call expressions
    437974 Total statements
     13491 Binary operators
      1888 Errors rewriting source
EOF

system("$ENV{CITRUN_TOOLS}/citrun-check /usr/ports/pobj/spidermonkey-* > check.out");
system("diff -u check.good check.out");

ok(1);
$package->clean();
