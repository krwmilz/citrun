use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 4;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
#include <stdio.h>

int
main(void)
{
	fprintf(stderr, "hello, world!");
	return 0;
}
EOF
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
#include <scv_runtime.h>
static uint64_t lines[9];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 9,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <stdio.h>

int
main(void)
{libscv_init();
	(++lines[6], fprintf(stderr, "hello, world!"));
	return (++lines[7], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, "hello, world!", "instrumented program check error message" );
