use strict;
use Test::More tests => 7;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();
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
{++_citrun_lines[4];++_citrun_lines[5];++_citrun_lines[6];
	if ((++_citrun_lines[7], n == 0))
		return (++_citrun_lines[8], 0);
	else if ((++_citrun_lines[9], n == 1))
		return (++_citrun_lines[10], 1);

	return (++_citrun_lines[12], (++_citrun_lines[12], fibonacci(n - 1)) + (++_citrun_lines[12], fibonacci(n - 2)));
}

int
main(int argc, char *argv[])
{citrun_start();++_citrun_lines[15];++_citrun_lines[16];++_citrun_lines[17];
	long long n;

	if ((++_citrun_lines[20], argc != 2)) {
		(++_citrun_lines[21], printf("usage: %s <N>", argv[0]));
		return (++_citrun_lines[22], 1);
	}

	n = (++_citrun_lines[25], atoi(argv[1]));

	(++_citrun_lines[27], printf("result: %lli", (++_citrun_lines[27], fibonacci(n))));

	return (++_citrun_lines[29], 0);
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
