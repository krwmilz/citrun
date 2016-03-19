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
#include <scv_runtime.h>
static uint64_t lines[21];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 21,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <stdlib.h>

int
main(int argc, char *argv[])
{libscv_init();
	if ((++lines[6], argc == 1))
		return (++lines[7], 1);
	else
		(++lines[9], exit(14));

	if ((++lines[11], argc == 2)) {
		return (++lines[12], 5);
	}
	else if ((++lines[14], argc == 3)) {
		return (++lines[15], 0);
	}
	else {
		(++lines[18], exit(0));
	}
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 1, "instrumented program check");
