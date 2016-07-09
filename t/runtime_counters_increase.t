use strict;

use Data::Dumper;
use Test::More tests => 19;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
my $viewer = Test::Viewer->new();
unified_diff;

$project->add_src(<<EOF);
#include <err.h>
#include <stdio.h>
#include <stdlib.h>

long long
fib(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;
	return fib(n - 1) + fib(n - 2);
}

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2)
		errx(1, "argc != 2");

	n = atoi(argv[1]);

	fprintf(stderr, "%lli", fib(n));
	return 0;
}
EOF

# Compile above inefficient program and let it run for a few seconds.
$project->compile();
$project->run(45);

# Accept the runtime connection and check a few things.
$viewer->accept();
is( $viewer->{num_tus}, 1, "num tus check" );
$viewer->cmp_static_data([ [ "source_0.c", 28, 18 ] ]);

my $data = $viewer->get_dynamic_data();
ok( keys %$data == 1, "single dynamic data key" );
my ($exec_lines1) = values %$data;

# Only lines 8 - 12 in the source code above are executing
for (8..12) {
	# Runtime sends execution differences.
	cmp_ok( $exec_lines1->[$_], ">", 0, "line $_ executed nonzero times" );
}

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "runtime sanity return code check" );
is( $err, undef, "runtime sanity program output" );
