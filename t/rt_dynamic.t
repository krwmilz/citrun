use strict;
use Test::More tests => 107;
use Test::Project;
use Test::Viewer;
use Time::HiRes qw( usleep );

my $project = Test::Project->new();
my $viewer = Test::Viewer->new();

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
$viewer->cmp_static_data([
	[ "source_0.c",	20 ],
	[ "source_1.c",	11 ],
	[ "source_2.c",	9 ],
]);

# Check initial execution counts
#
my $data = $viewer->get_dynamic_data();
my ($s0, $s1, $s2) = sort keys %$data;

my @lines = @{ $data->{$s0} };
is( $lines[$_], 0, "src 0 line $_ check" ) for (0..5);
is( $lines[$_], 1, "src 0 line $_ check" ) for (6..8);
is( $lines[$_], 0, "src 0 line $_ check" ) for (9..10);
is( $lines[11], 1, "src 0 line 11 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (12..13);
is( $lines[14], 1, "src 0 line 14 check" );
is( $lines[15], 0, "src 0 line 15 check" );
is( $lines[16], 2, "src 0 line 16 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (17..18);

my @lines = @{ $data->{$s1} };
cmp_ok ( $lines[$_], ">", 1, "src 1 line $_ check" ) for (0..2);
cmp_ok ( $lines[$_], ">", 10, "src 1 line $_ check" ) for (3..6);
is( $lines[7], 0, "src 1 line 7 check" );
cmp_ok( $lines[8], ">", 10, "src 1 line 8 check" );
is( $lines[9],		0, "src 1 line 9 check" );

my @lines = @{ $data->{$s2} };
is( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

for (1..60) {
	usleep(10 * 1000);
	$viewer->cmp_dynamic_data();
}

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
