use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 7;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
#include <stdio.h>
#include <stdlib.h>

long long
fibonacci(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2) {
		fprintf(stderr, "usage: %s <N>", argv[0]);
		return 1;
	}

	n = atoi(argv[1]);

	fprintf(stderr, "result: %lli", fibonacci(n));

	return 0;
}
EOF
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
#include <scv_runtime.h>
static uint64_t lines[31];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 31,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <stdio.h>
#include <stdlib.h>

long long
fibonacci(long long n)
{
	if ((++lines[7], n == 0))
		return (++lines[8], 0);
	else if ((++lines[9], n == 1))
		return (++lines[10], 1);

	return (++lines[12], (++lines[12], fibonacci(n - 1)) + (++lines[12], fibonacci(n - 2)));
}

int
main(int argc, char *argv[])
{libscv_init();
	long long n;

	if ((++lines[20], argc != 2)) {
		(++lines[21], fprintf(stderr, "usage: %s <N>", argv[0]));
		return (++lines[22], 1);
	}

	n = (++lines[25], atoi(argv[1]));

	(++lines[27], fprintf(stderr, "result: %lli", (++lines[27], fibonacci(n))));

	return (++lines[29], 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret, $err) = $project->wait();
is($ret, 1, "instrumented program check return code");

$project->run(10);
my ($ret, $err) = $project->wait();
is($ret, 0, "instrumented program check correctness 1");
is($err, "result: 55", "instrumented program check correctness 1");

$project->run(20);
my ($ret, $err) = $project->wait(20);
is($ret, 0, "instrumented program check correctness 2");
is($err, "result: 6765", "instrumented program check correctness 2");
