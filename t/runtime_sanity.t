use strict;

use Data::Dumper;
use Test::More tests => 50;
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

# Request and check metadata first
my $runtime_metadata = $viewer->get_metadata();
my $tus_ordered = $runtime_metadata->{tus_ordered};
my $tus = $runtime_metadata->{tus};

my ($fn0, $fn1, $fn2) = sort keys %$tus;
like( $fn0, qr/.*source_0.c/, "runtime filename check 0" );
is( $tus->{$fn0}->{lines}, 20, "runtime line count check 0" );
my $sites0 = $tus->{$fn0}->{inst_sites};
cmp_ok( $sites0, ">=", 6, "site count 0 lower" );
cmp_ok( $sites0, "<=", 11, "site count 0 upper" );

like( $fn1, qr/.*source_1.c/, "runtime filename check 1" );
is( $tus->{$fn1}->{lines}, 11, "runtime line count check 1" );
is( $tus->{$fn1}->{inst_sites}, 7, "instrumented site count 1" );

like( $fn2, qr/.*source_2.c/, "runtime filename check 2" );
is( $tus->{$fn2}->{lines}, 9, "runtime line count check 2" );
my $sites2 = $tus->{$fn2}->{inst_sites};
cmp_ok( $sites2, ">=", 5, "site count 2 lower" );
cmp_ok( $sites2, "<=", 6, "site count 2 upper" );

# Request and check execution data
my $data = $viewer->get_execution_data($tus_ordered, $tus);

my @lines = @{ $data->{$fn0} };
is( $lines[$_], 0, "src 0 line $_ check" ) for (1..11);
is( $lines[12], 1, "src 0 line 14 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (13..14);
is( $lines[15], 1, "src 0 line 15 check" );
is( $lines[16], 0, "src 0 line 16 check" );
is( $lines[17], 2, "src 0 line 17 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (18..19);

my @lines = @{ $data->{$fn1} };
is( $lines[$_], 0, "src 1 line $_ check" ) for (0..3);
cmp_ok ( $lines[$_], ">", 10, "src 1 line $_ check" ) for (4..7);
is( $lines[8], 0, "src 1 line 8 check" );

my @lines = @{ $data->{$fn2} };
is( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
