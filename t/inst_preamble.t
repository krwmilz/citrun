use strict;
use Test::More tests => 4;
use Test::Differences;

use Test::Project;

my $project = Test::Project->new();
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

$tmp_dir = substr( $tmp_dir, 8 ) if ($^O eq "darwin");

my $preamble_good = <<EOF;
#ifdef __cplusplus
extern "C" {
#endif
#include <stdint.h>
#include <stddef.h>
struct citrun_node {
	uint64_t *lines_ptr;
	uint32_t size;
	uint32_t inst_sites;
	const char *file_name;
	struct citrun_node *next;
};
void citrun_node_add(struct citrun_node *);
void citrun_start();

static uint64_t _citrun_lines[6];
static struct citrun_node _citrun_node = {
	.lines_ptr = _citrun_lines,
	.size = 6,
	.inst_sites = 1,
	.file_name = "$tmp_dir/source_0.c",
};
__attribute__((constructor))
static void citrun_constructor() {
	citrun_node_add(&_citrun_node);
}
#ifdef __cplusplus
}
#endif
EOF

my $preamble = $project->inst_src_preamble();
ok( $preamble );

eq_or_diff $preamble, $preamble_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is($ret, 0, "return code");
is($err, undef, "stderr empty");
