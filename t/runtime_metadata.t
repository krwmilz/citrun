use strict;

use Test::More tests => 11;

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

# Request and check metadata first
my $runtime_metadata = $viewer->get_metadata();

my $pid = $runtime_metadata->{pid};
my $ppid = $runtime_metadata->{ppid};
my $pgrp = $runtime_metadata->{pgrp};

cmp_ok( $pid,  ">", 1, "pid is positive" );
cmp_ok( $ppid, ">", 1, "ppid is positive" );
cmp_ok( $pgrp, ">", 1, "pgrp is positive" );

cmp_ok( $pid,  "<", 100 * 1000, "pid is a reasonable value" );
cmp_ok( $ppid, "<", 100 * 1000, "ppid is a reasonable value" );
cmp_ok( $pgrp, "<", 100 * 1000, "pgrp is a reasonable value" );

my $tus = $runtime_metadata->{tus};
is ( scalar(keys %$tus), 1, "translation unit count" );

my ($file_name) = keys %$tus;
like( $file_name, qr/.*source_0.c/, "filename check" );
is( $tus->{$file_name}->{lines}, 8, "line count check" );

$project->kill();
my ($ret, $err) = $project->wait();
is( $ret, 0, "instrumented program check return code" );
is( $err, undef, "instrumented program check stderr" );
