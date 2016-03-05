use strict;
use SCV::Project;
use Test::More tests => 3;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
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
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
unsigned int lines[78];
int size = 78;
char file_name[] = "$tmp_dir/source.c";
int
main(void)
{
	int i;

	for (i = 0; (lines[6] = 1, i < 19); i++) {
		i++;
	}

	return (lines[10] = 1, i);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret) = $project->run();
is($ret, 20, "instrumented program check");
