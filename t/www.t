#
# Test live website.
#
use strict;
use warnings;
use Test::More tests => 5;
use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok( "http://cit.run" );
$mech->base_is( "http://cit.run" );
$mech->title_is( "C It Run" );

$mech->html_lint_ok();

$mech->page_links_ok("check all links");
