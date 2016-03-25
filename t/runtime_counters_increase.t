use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 14;
use Test::Differences;

my $project = SCV::Project->new();
my $viewer = SCV::Viewer->new();
unified_diff;

$project->add_src(<<EOF
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
);

# Compile the above inefficient program and have it compute the input 40, which
# takes a few seconds
$project->compile();
$project->run(45);

# Accept the runtime's connection
$viewer->accept();
my $runtime_metadata = $viewer->get_metadata();
my $tus = $runtime_metadata->{tus};

my $source_0 = $tus->[0];
like ($source_0->{filename}, qr/.*source_0\.c/, "runtime filename check");
is( $source_0->{lines}, 28, "runtime lines count" );

my $data = $viewer->get_execution_data($tus);
my @exec_lines1 = @{ $data->[0] };

my $data = $viewer->get_execution_data($tus);
my @exec_lines2 = @{ $data->[0] };

# Only lines 8 - 12 in the source code above are executing
for (8..12) {
	cmp_ok( $exec_lines1[$_], ">", 0, "line $_ executed nonzero times" );
	# Make sure the second time we queried the execution counts they were higher
	cmp_ok( $exec_lines2[$_], ">=", $exec_lines1[$_], "line $_ after > before" );
}

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "runtime sanity return code check" );
is( $err, undef, "runtime sanity program output" );
