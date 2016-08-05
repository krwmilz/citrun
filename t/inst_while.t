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

	i = 0;
	while (i < 17) {
		i++;
	}

	return i;
}
EOF

$project->compile();
$project->run();

my ($ret) = $project->wait();
is($ret, 17, "instrumented program check");
