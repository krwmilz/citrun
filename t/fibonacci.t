use strict;
use Test::More tests => 5;
use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();

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
