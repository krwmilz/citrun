use strict;

use Test::More tests => 5;

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

# Request and check metadata first
my $runtime_metadata = $viewer->get_metadata();

my $tus = $runtime_metadata->{tus};
is ( scalar(keys %$tus), 1, "translation unit count" );

my ($file_name) = keys %$tus;
like( $file_name, qr/.*source_0.c/, "filename check" );
is( $tus->{$file_name}->{lines}, 7, "line count check" );

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
