use strict;

use Data::Dumper;
use Test::More tests => 45;
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
my $tus = $runtime_metadata->{tus};

my ($source_0, $source_1, $source_2) = @$tus;
like( $source_0->{filename}, qr/.*source_2.c/, "runtime filename check 0" );
is( $source_0->{lines}, 9, "runtime line count check 0" );
#is( $source_0->{inst_sites}, 7, "instrumented site count 0" );

like( $source_1->{filename}, qr/.*source_1.c/, "runtime filename check 1" );
is( $source_1->{lines}, 11, "runtime line count check 1" );
#is( $source_1->{inst_sites}, 7, "instrumented site count 1" );

like( $source_2->{filename}, qr/.*source_0.c/, "runtime filename check 2" );
is( $source_2->{lines}, 20, "runtime line count check 2" );
#is( $source_2->{inst_sites}, 6, "instrumented site count 2" );

# Request and check execution data
my $data = $viewer->get_execution_data($tus);

my @lines = @{ $data->[2] };
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (1..11);
is     ( $lines[12], 1, "src 0 line 14 check" );
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (13..14);
is     ( $lines[15], 1, "src 0 line 15 check" );
is     ( $lines[16], 0, "src 0 line 16 check" );
is     ( $lines[17], 2, "src 0 line 17 check" );
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (18..19);

my @lines = @{ $data->[1] };
is     ( $lines[$_], 0, "src 1 line $_ check" ) for (0..3);
cmp_ok ( $lines[$_], ">", 10, "src 1 line $_ check" ) for (4..7);
is     ( $lines[8], 0, "src 1 line 8 check" );

my @lines = @{ $data->[0] };
is     ( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
