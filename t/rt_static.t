use strict;
use Cwd;
use Test::More tests => 18;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF);
int
main(void)
{
	while (1);
	return 0;
}
EOF
$project->compile();
$project->run();

$viewer->accept();
is( $viewer->{maj}, 	0,	"protocol major version" );
is( $viewer->{min}, 	0,	"protocol minor version" );
is( $viewer->{ntus},	1,	"translation unit count" );
is( $viewer->{nlines},	7,	"total program lines" );
is( $viewer->{progname}, "program", "program name" );
is( $viewer->{cwd},	getcwd,	"current working dir" );
is( @{ $viewer->{pids} },	3,	"number of pids" );
cmp_ok( $viewer->{pids}->[0],	">",	1,	"pid check lower" );
cmp_ok( $viewer->{pids}->[0],	"<",	100000,	"pid check upper" );
cmp_ok( $viewer->{pids}->[1],	">",	1,	"ppid check lower" );
cmp_ok( $viewer->{pids}->[1],	"<",	100000,	"ppid check upper" );
cmp_ok( $viewer->{pids}->[2],	">",	1,	"pgrp check lower" );
cmp_ok( $viewer->{pids}->[2],	"<",	100000,	"pgrp check upper" );

$viewer->cmp_static_data([ [ "source_0.c", 7 ] ]);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
