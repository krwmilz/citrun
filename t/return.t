use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 3;
use Test::Differences;

my $viewer = SCV::Viewer->new();
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
#include <stdint.h>
struct _scv_node {
	uint64_t *lines_ptr;
	uint32_t size;
	uint32_t inst_sites;
	const char *file_name;
	struct _scv_node *next;
};
void libscv_init();

static uint64_t _scv_lines[12];
struct _scv_node _scv_node1;
struct _scv_node _scv_node0 = {
	.lines_ptr = _scv_lines,
	.size = 12,
	.inst_sites = 5,
	.file_name = "$tmp_dir/source_0.c",
	.next = &_scv_node1,
};
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
