use strict;
use SCV::Project;
use Test::More tests => 4;
use Test::Differences;

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
#include <scv_global.h>
static unsigned int lines[85];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 85,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <stdio.h>

int
main(void)
{
	(lines[6] = 1, fprintf(stderr, "hello, world!"));
	return (lines[7] = 1, 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret, $err) = $project->run();
is( $ret, 0, "instrumented program check return code" );

is( $err, "hello, world!", "instrumented program check error message" );
