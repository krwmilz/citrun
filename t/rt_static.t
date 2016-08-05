use strict;
use Test::More tests => 16;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF);
int
main(void)
{
	/* Just do something so we can probe the runtime reliably */
	while (1);
	return 0;
}
EOF

$project->compile();
$project->run();

$viewer->accept();

is( $viewer->{maj}, 	0,	"major version" );
is( $viewer->{min}, 	0,	"minor version" );
is( scalar @{ $viewer->{pids} },	3,	"number of pids" );
cmp_ok( $viewer->{pids}->[0],	">",	1,	"pid check lower" );
cmp_ok( $viewer->{pids}->[0],	"<",	100000,	"pid check upper" );
cmp_ok( $viewer->{pids}->[1],	">",	1,	"ppid check lower" );
cmp_ok( $viewer->{pids}->[1],	"<",	100000,	"ppid check upper" );
cmp_ok( $viewer->{pids}->[2],	">",	1,	"pgrp check lower" );
cmp_ok( $viewer->{pids}->[2],	"<",	100000,	"pgrp check upper" );
is( $viewer->{num_tus}, 1, "translation unit count" );

my @known_good = [ [ "source_0.c", 8, 2 ] ];
$viewer->cmp_static_data(@known_good);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
