use strict;

use Test::More tests => 13;

use Test::Project;
use Test::Viewer;

my $viewer = Test::Viewer->new();
my $project = Test::Project->new();

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
is( $viewer->{num_tus}, 1, "translation unit count" );

my @known_good = [ [ "source_0.c", 8, 2 ] ];
$viewer->cmp_static_data(@known_good);

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
