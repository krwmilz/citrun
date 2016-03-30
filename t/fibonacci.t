use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 7;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

$project->add_src(<<EOF);
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
		printf("usage: %s <N>", argv[0]);
		return 1;
	}

	n = atoi(argv[1]);

	printf("result: %lli", fibonacci(n));

	return 0;
}
EOF

$project->compile();

my $inst_src_good = <<EOF;
#include <stdio.h>
#include <stdlib.h>

long long
fibonacci(long long n)
{
	if ((++_scv_lines[7], n == 0))
		return (++_scv_lines[8], 0);
	else if ((++_scv_lines[9], n == 1))
		return (++_scv_lines[10], 1);

	return (++_scv_lines[12], (++_scv_lines[12], fibonacci(n - 1)) + (++_scv_lines[12], fibonacci(n - 2)));
}

int
main(int argc, char *argv[])
{libscv_init();
	long long n;

	if ((++_scv_lines[20], argc != 2)) {
		(++_scv_lines[21], printf("usage: %s <N>", argv[0]));
		return (++_scv_lines[22], 1);
	}

	n = (++_scv_lines[25], atoi(argv[1]));

	(++_scv_lines[27], printf("result: %lli", (++_scv_lines[27], fibonacci(n))));

	return (++_scv_lines[29], 0);
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
my ($ret, $err) = $project->wait();
is($ret, 0, "instrumented program check correctness 2");
is($err, "result: 6765", "instrumented program check correctness 2");
