use strict;
use Test::More tests => 1;

my $ret = system( "webtidy index.html" );
is( $ret, 0, "index.html is tidy" );
