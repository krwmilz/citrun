use strict;
use Test::More tests => 1;

my $ret = system( "validate www/index.html" );
is( $ret, 0, "www/index.html validates");
