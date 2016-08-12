use strict;
use Test::More tests => 107;
use test::project;
use test::viewer;
use Time::HiRes qw( usleep );

my $project = test::project->new();
my $viewer = test::viewer->new();

$project->run(45);

$viewer->accept();
$viewer->cmp_static_data([
	[ "one.c",	20 ],
	[ "three.c",	9 ],
	[ "two.c",	11 ],
]);

# Check initial execution counts
#
my $data = $viewer->get_dynamic_data();
my ($s0, $s1, $s2) = sort keys %$data;

my @lines = @{ $data->{$s0} };
is( $lines[$_], 0, "src 0 line $_ check" ) for (0..5);
is( $lines[$_], 1, "src 0 line $_ check" ) for (6..8);
is( $lines[$_], 0, "src 0 line $_ check" ) for (9..10);
is( $lines[11], 2, "src 0 line 11 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (12..13);
is( $lines[14], 2, "src 0 line 14 check" );
is( $lines[15], 0, "src 0 line 15 check" );
is( $lines[16], 2, "src 0 line 16 check" );
is( $lines[$_], 0, "src 0 line $_ check" ) for (17..18);

my @lines = @{ $data->{$s2} };
cmp_ok ( $lines[$_], ">", 1, "src 1 line $_ check" ) for (0..2);
cmp_ok ( $lines[$_], ">", 10, "src 1 line $_ check" ) for (3..6);
is( $lines[7], 0, "src 1 line 7 check" );
cmp_ok( $lines[8], ">", 10, "src 1 line 8 check" );
is( $lines[9],		0, "src 1 line 9 check" );

my @lines = @{ $data->{$s1} };
is( $lines[$_], 0, "src 2 line $_ check" ) for (0..8);

for (1..60) {
	usleep(10 * 1000);
	$viewer->cmp_dynamic_data();
}

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
