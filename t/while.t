use strict;

use Test::More tests => 3;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Project->new();
my $project = Test::Project->new();
unified_diff;

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

my $inst_src_good = <<EOF;
int
main(void)
{
	int i;

	i = 0;
	while ((++_citrun_lines[7], i < 17)) {
		i++;
	}

	return (++_citrun_lines[11], i);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 17, "instrumented program check");
