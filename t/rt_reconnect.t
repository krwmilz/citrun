use strict;
use Test::More tests => 8;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();

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

# Give the runtime a chance to reconnect
sleep(1);

my $viewer = Test::Viewer->new();
$viewer->accept();
is( $viewer->{ntus}, 1, "num tus check" );
$viewer->cmp_static_data([ [ "source_0.c", 7, 2 ] ]);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
