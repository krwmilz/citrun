use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 38;
use Test::Differences;
use Time::HiRes qw( usleep );

my $project = SCV::Project->new();
my $viewer = SCV::Viewer->new();
unified_diff;

$project->add_src(
<<EOF
#include <err.h>
#include <limits.h>
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
	const char *errstr = NULL;

	if (argc != 2)
		errx(1, "argc != 2");

	n = strtonum(argv[1], LONG_MIN, LONG_MAX, &errstr);
	if (errstr)
		err(1, "%s", errstr);

	fprintf(stderr, "%lli", fib(n));
	return 0;
}
EOF
);

# Compile the above inefficient program and have it compute the input 40, which
# takes a few seconds
$project->compile();
$project->run(45);

# Accept the runtime's connection
$viewer->accept();
my $metadata = $viewer->get_metadata();
is( scalar(@{ $metadata }), 1, "runtime check for a single tu" );

my $source_0 = $metadata->[0];
like ($source_0->{filename}, qr/tmp\/.*source_0\.c/, "runtime filename check");
is( $source_0->{lines}, 33, "runtime lines count" );

usleep(100 * 1000);
my $data = $viewer->get_execution_data();

my @lines = @{ $data->[0] };
# Do a pretty thorough coverage check
is     ( $lines[$_], 0, "line $_ check" ) for (0..8);
cmp_ok ( $lines[$_], ">", 0, "line $_ check" ) for (9..12);
is     ( $lines[13], 0, "line 13 check" );
cmp_ok ( $lines[14], ">", 0, "line 14 check" );
is     ( $lines[$_], 0, "line $_ check" ) for (15..22);
is     ( $lines[23], 1, "line 23 check" );
is     ( $lines[$_], 0, "line $_ check" ) for (24..25);
is     ( $lines[$_], 1, "line $_ check" ) for (26..27);
is     ( $lines[$_], 0, "line $_ check" ) for (28..29);
is     ( $lines[30], 2, "line 30 check" );
# Make sure return code hasn't fired yet
is     ( $lines[$_], 0, "line $_ check" ) for (31..32);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "runtime sanity return code check" );
is( $err, undef, "runtime sanity program output" );
