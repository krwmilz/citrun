use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 4;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

$project->add_src(<<EOF);
#include <stdio.h>

int
main(void)
{
	printf("hello, world!");
	return 0;
}
EOF

$project->compile();

my $inst_src_good = <<EOF;
#include <stdio.h>

int
main(void)
{
	(++_citrun_lines[6], printf("hello, world!"));
	return (++_citrun_lines[7], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, "hello, world!", "instrumented program check error message" );
