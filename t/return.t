use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 3;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
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
int foo() {
	return (++_scv_lines[2], 0);
}

int main(void) {libscv_init();
	return (++_scv_lines[6], 10);

	return (++_scv_lines[8], 10 + 10);

	return (++_scv_lines[10], (++_scv_lines[10], foo()));
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 10, "instrumented program check");
