use strict;
use SCV::Project;
use Test::More tests => 3;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
unsigned int lines[91];
int size = 91;
char file_name[] = "$tmp_dir/source.c";
int foo() {
	return (lines[2] = 1, 0);
}

int main(void) {
	return (lines[6] = 1, 10);

	return (lines[8] = 1, 10 + 10);

	return (lines[10] = 1, (lines[10] = 1, foo()));
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret) = $project->run();
is($ret, 10, "instrumented program check");
