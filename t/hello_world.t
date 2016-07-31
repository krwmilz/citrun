use strict;
use Test::More tests => 2;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
$ENV{CITRUN_SOCKET} = $project->tmpdir() . "/test.socket";
my $viewer = Test::Viewer->new();

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
$project->run();

my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, "hello, world!", "instrumented program check error message" );
