use strict;
use Test::More tests => 1;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
$ENV{CITRUN_SOCKET} = $project->tmpdir() . "/test.socket";
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF);
int
main(void)
{
	int i;

	for (i = 0; i < 19; i++) {
		i++;
	}

	return i;
}
EOF

$project->compile();
$project->run();

my ($ret) = $project->wait();
is($ret, 20, "instrumented program check");
