#
# Test live website has correct html and no broken links.
#
use Modern::Perl;
use Test::More skip_all => 'utf8 index false positive';
use Test::WWW::Mechanize;


my $mech = Test::WWW::Mechanize->new;

$mech->get_ok("http://cit.run");
# $mech->base_is("http://cit.run");
$mech->title_is("C It Run", "title is 'C It Run'");
$mech->html_lint_ok("is html correct");
$mech->page_links_ok("is no broken links");
