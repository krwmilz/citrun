use strict;

use Data::Dumper;
use Test::More tests => 58;
use Test::Differences;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();
unified_diff;

$project->add_src(<<EOF);
#include <err.h>
#include <stdlib.h>

long long fib(long long);
void print_output(long long);

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2)
		errx(1, "argc != 2");

	n = atoi(argv[1]);

	print_output(fib(n));
	return 0;
}
EOF

$project->add_src(<<EOF);
long long
fib(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fib(n - 1) + fib(n - 2);
}
EOF

$project->add_src(<<EOF);
#include <stdio.h>

void
print_output(long long n)
{
	fprintf(stderr, "%lli", n);
	return;
}
EOF

$project->compile();
$project->run(45);

$viewer->accept();
is( $viewer->{num_tus}, 3, "translation unit count" );

# Check static data.
my @known_good = [
	# filename	lines	inst sites
	[ "source_0.c",	20,	9 ],
	[ "source_1.c",	11,	7 ],
	[ "source_2.c",	9,	6 ],
];
$viewer->cmp_static_data(@known_good);

# Request and check execution data.
my $data = $viewer->get_dynamic_data();

# The nodes can be in any order.
my ($s0, $s1, $s2) = sort keys %$data;

my @lines = @{ $data->{$s0} };
is( $lines[$_], 0, "src 0 line $_ check" ) for (1..11);
is( $lines[12], 1, "src 0 line 14 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (13..14);
is( $lines[15], 1, "src 0 line 15 check" );
is( $lines[16], 0, "src 0 line 16 check" );
is( $lines[17], 2, "src 0 line 17 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (18..19);

my @lines = @{ $data->{$s1} };
is( $lines[$_], 0, "src 1 line $_ check" ) for (0..3);
cmp_ok ( $lines[$_], ">", 10, "src 1 line $_ check" ) for (4..7);
is( $lines[8], 0, "src 1 line 8 check" );

my @lines = @{ $data->{$s2} };
is( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
