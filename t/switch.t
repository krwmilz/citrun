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
{libscv_init();
	int i;

	switch ((++_scv_lines[6], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_scv_lines[13], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 0, "instrumented program check");
