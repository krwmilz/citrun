use strict;
use Test::More tests => 1;
use Test::Project;

my $project = Test::Project->new();

$project->add_src(<<EOF);
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	if (argc == 1)
		return 1;
	else
		exit(14);

	if (argc == 2) {
		return 5;
	}
	else if (argc == 3) {
		return 0;
	}
	else {
		exit(0);
	}
}
EOF

$project->compile();
$project->run();

my ($ret) = $project->wait();
is($ret, 1, "instrumented program check");
