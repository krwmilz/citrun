#
# Test that we can count an executing program as its running.
#
use strict;
use warnings;
use LWP::UserAgent;
use Test::HTML::Tidy tests => 2;
use Test::More;

my $ua = LWP::UserAgent->new();
my $resp = $ua->get("http://cit.run");

ok( $resp->is_success, "is http response success" );

html_tidy_ok($resp->decoded_content, "is html tidy");
