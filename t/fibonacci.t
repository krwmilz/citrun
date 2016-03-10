use strict;
use SCV::Project;
use Test::More tests => 7;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(
<<EOF
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

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
	const char *errstr = NULL;

	if (argc != 2) {
		fprintf(stderr, "usage: %s <N>\\n", argv[0]);
		return 1;
	}

	n = strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr);
	if (errstr)
		err(1, "%s", errstr);

	fprintf(stderr, "result: %lli\\n", fibonacci(n));

	return 0;
}
EOF
);

$project->compile();

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
#include <scv_global.h>
static unsigned int lines[530];
struct scv_node node1;
struct scv_node node0 = {
	.lines_ptr = lines,
	.size = 530,
	.file_name = "$tmp_dir/source_0.c",
	.next = &node1,
};
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

long long
fibonacci(long long n)
{
	if ((lines[9] = 1, n == 0))
		return (lines[10] = 1, 0);
	else if ((lines[11] = 1, n == 1))
		return (lines[12] = 1, 1);

	return (lines[14] = 1, (lines[14] = 1, fibonacci(n - 1)) + (lines[14] = 1, fibonacci(n - 2)));
}

int
main(int argc, char *argv[])
{
	long long n;
	const char *errstr = NULL;

	if ((lines[23] = 1, argc != 2)) {
		(lines[24] = 1, fprintf(stderr, "usage: %s <N>\\n", argv[0]));
		return (lines[25] = 1, 1);
	}

	n = (lines[28] = 1, strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr));
	if ((lines[29] = 1, errstr))
		(lines[30] = 1, err(1, "%s", errstr));

	(lines[32] = 1, fprintf(stderr, "result: %lli\\n", (lines[32] = 1, fibonacci(n))));

	return (lines[34] = 1, 0);
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret, $err) = $project->run();
is($ret, 1, "instrumented program check return code");

my ($ret, $err) = $project->run(10);
is($ret, 0, "instrumented program check correctness 1");
is($err, "result: 55\n", "instrumented program check correctness 1");

my ($ret, $err) = $project->run(20);
is($ret, 0, "instrumented program check correctness 2");
is($err, "result: 6765\n", "instrumented program check correctness 2");
