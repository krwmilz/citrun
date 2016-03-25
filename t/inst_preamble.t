use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 4;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(<<EOF);
int
main(void)
{
	return 0;
}
EOF

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $preamble_good = <<EOF;
#include <stdint.h>
struct _scv_node {
	uint64_t *lines_ptr;
	uint32_t size;
	uint32_t inst_sites;
	const char *file_name;
	struct _scv_node *next;
};
void libscv_init();

static uint64_t _scv_lines[6];
struct _scv_node _scv_node1;
struct _scv_node _scv_node0 = {
	.lines_ptr = _scv_lines,
	.size = 6,
	.inst_sites = 1,
	.file_name = "$tmp_dir/source_0.c",
	.next = &_scv_node1,
};
EOF

my $preamble = $project->inst_src_preamble();
ok( $preamble );

eq_or_diff $preamble, $preamble_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is($ret, 0, "return code");
is($err, undef, "stderr empty");
