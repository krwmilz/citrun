use strict;

use Test::More tests => 3;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();
unified_diff;

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

my $inst_src_good = <<EOF;
int
main(void)
{citrun_start();
	int i;

	switch ((++_citrun_lines[6], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun_lines[13], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 0, "instrumented program check");
