use strict;
use Data::Dumper;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 47;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

$project->add_src(<<EOF
#include <err.h>
#include <limits.h>
#include <stdlib.h>	/* strtonum */

long long fib(long long);
void print_output(long long);

int
main(int argc, char *argv[])
{
	long long n;
	const char *errstr = NULL;

	if (argc != 2)
		errx(1, "argc != 2");

	n = strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr);
	if (errstr)
		err(1, "%s", errstr);

	print_output(fib(n));
	return 0;
}
EOF
);

$project->add_src(<<EOF
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
);

$project->add_src(<<EOF
#include <stdio.h>

void
print_output(long long n)
{
	fprintf(stderr, "%lli", n);
	return;
}
EOF
);

$project->compile();
$project->run(45);

$viewer->accept();
my $data = $viewer->request_data();

like ($_, qr/tmp\/.*source_.*\.c/, "runtime filename check") for (keys %$data);
my ($src_filename_0, $src_filename_1, $src_filename_2) = sort keys %$data;

my @lines = @{ $data->{$src_filename_0} };
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (0..13);
is     ( $lines[14], 1, "src 0 line 14 check" );
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (15..16);
is     ( $lines[$_], 1, "src 0 line $_ check" ) for (17..18);
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (19..20);
is     ( $lines[21], 2, "src 0 line 21 check" );
is     ( $lines[$_], 0, "src 0 line $_ check" ) for (22..23);

my @lines = @{ $data->{$src_filename_1} };
is     ( $lines[$_], 0, "src 1 line $_ check" ) for (0..3);
cmp_ok ( $lines[$_], ">", 100, "src 1 line $_ check" ) for (4..7);
is     ( $lines[8], 0, "src 1 line 8 check" );

my @lines = @{ $data->{$src_filename_2} };
is     ( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
