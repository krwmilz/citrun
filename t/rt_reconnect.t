use strict;
use Test::More tests => 9;
use test::project;
use test::viewer;

my $project = test::project->new();

$project->run(45);

# Give the runtime a chance to reconnect
sleep(1);

my $viewer = test::viewer->new();
$viewer->accept();
$viewer->cmp_static_data([
	[ "one.c",	20 ],
	[ "three.c",	9 ],
	[ "two.c",	11 ],
]);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
