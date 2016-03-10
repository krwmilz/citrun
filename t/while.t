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

	i = 0;
	while (i < 17) {
		i++;
	}

	return i;
}
EOF
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
#include <scv_global.h>
static unsigned int lines[76];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 76,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
int
main(void)
{
	int i;

	i = 0;
	while ((lines[7] = 1, i < 17)) {
		i++;
	}

	return (lines[11] = 1, i);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret) = $project->run();
is($ret, 17, "instrumented program check");
