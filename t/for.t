use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 3;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

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

my $inst_src_good = <<EOF;
int
main(void)
{libscv_init();
	int i;

	for (i = 0; (++_citrun_lines[6], i < 19); i++) {
		i++;
	}

	return (++_citrun_lines[10], i);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 20, "instrumented program check");
