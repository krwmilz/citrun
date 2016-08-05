use strict;
use Test::More tests => 1;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF);
int
main(void)
{
	int i;

	switch (i) {
	case 0:
		break;
	case 1:
		break;
	}

	return 0;
}
EOF

$project->compile();
$project->run();

my ($ret) = $project->wait();
is($ret, 0, "instrumented program check");
