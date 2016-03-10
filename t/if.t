use strict;
use SCV::Project;
use Test::More tests => 3;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
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
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
#include <scv_global.h>
static unsigned int lines[198];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 198,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	if ((lines[6] = 1, argc == 1))
		return (lines[7] = 1, 1);
	else
		(lines[9] = 1, exit(14));

	if ((lines[11] = 1, argc == 2)) {
		return (lines[12] = 1, 5);
	}
	else if ((lines[14] = 1, argc == 3)) {
		return (lines[15] = 1, 0);
	}
	else {
		(lines[18] = 1, exit(0));
	}
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret) = $project->run();
is($ret, 1, "instrumented program check");
