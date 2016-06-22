use strict;
use Test::More tests => 1;

# --spider: don't download the page
# -r: recursive retrieval
# -nd: don't create local dirs
# -nv: turn off extra downloading output
# -H: span accross hosts
# -l: recursion level
my $ret = system( "wget --spider -r -nd -nv -H -l 1 http://cit.run" );
is( $ret, 0, "http://cit.run/ has no broken links" );
