use strict;
use Cwd;
use Test::More tests => 21;
use test::project;
use test::viewer;

my $project = test::project->new();
my $viewer = test::viewer->new();

$project->run(45);

$viewer->accept();
is( $viewer->{maj}, 	0,	"protocol major version" );
is( $viewer->{min}, 	0,	"protocol minor version" );
is( $viewer->{ntus},	3,	"translation unit count" );
is( $viewer->{progname}, "program", "program name" );
is( $viewer->{cwd},	getcwd,	"current working dir" );
is( @{ $viewer->{pids} },	3,	"number of pids" );
cmp_ok( $viewer->{pids}->[0],	">",	1,	"pid check lower" );
cmp_ok( $viewer->{pids}->[0],	"<",	100000,	"pid check upper" );
cmp_ok( $viewer->{pids}->[1],	">",	1,	"ppid check lower" );
cmp_ok( $viewer->{pids}->[1],	"<",	100000,	"ppid check upper" );
cmp_ok( $viewer->{pids}->[2],	">",	1,	"pgrp check lower" );
cmp_ok( $viewer->{pids}->[2],	"<",	100000,	"pgrp check upper" );

$viewer->cmp_static_data([
		[ "one.c", 34 ],
		[ "three.c", 9 ],
		[ "two.c", 11 ],
]);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
