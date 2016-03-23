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
#include <stdint.h>
struct _scv_node {
	uint64_t *lines_ptr;
	uint64_t size;
	const char *file_name;
	struct _scv_node *next;
};
void libscv_init();

static uint64_t _scv_lines[9];
struct _scv_node _scv_node1;
struct _scv_node _scv_node0 = {
	.lines_ptr = _scv_lines,
	.size = 9,
	.file_name = "$tmp_dir/source_0.c",
	.next = &_scv_node1,
};
#include <stdio.h>

int
main(void)
{libscv_init();
	(++_scv_lines[6], fprintf(stderr, "hello, world!"));
	return (++_scv_lines[7], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, "hello, world!", "instrumented program check error message" );
