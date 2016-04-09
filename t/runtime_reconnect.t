use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 5;

my $project = SCV::Project->new();

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

my $viewer = SCV::Viewer->new();
$viewer->accept();

# Request and check metadata first
my $runtime_metadata = $viewer->get_metadata();

my $tus = $runtime_metadata->{tus};
is ( scalar(@$tus), 1, "translation unit count" );
my $tu = $tus->[0];

like( $tu->{filename}, qr/.*source_0.c/, "filename check" );
is( $tu->{lines}, 7, "line count check" );

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
