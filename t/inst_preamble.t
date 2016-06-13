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
};

static uint64_t _citrun_lines[6];
struct citrun_node citrun_node_source_0 = {
	.lines_ptr = _citrun_lines,
	.size = 6,
	.inst_sites = 1,
	.file_name = "$tmp_dir/source_0.c",
};
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
