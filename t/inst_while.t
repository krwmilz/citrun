use strict;
use Test::More tests => 1;
use Test::Project;
use Test::Viewer;

my $viewer = Test::Project->new();
my $project = Test::Project->new();

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
