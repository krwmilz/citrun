use strict;

use Test::More tests => 3;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();
unified_diff;

$project->add_src(<<EOF);
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF

$project->compile();

my $inst_src_good = <<EOF;
int foo() {++_citrun_lines[1];
	return (++_citrun_lines[2], 0);
}

int main(void) {citrun_start();++_citrun_lines[5];
	return (++_citrun_lines[6], 10);

	return (++_citrun_lines[8], 10 + 10);

	return (++_citrun_lines[10], (++_citrun_lines[10], foo()));
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 10, "instrumented program check");
