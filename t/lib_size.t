#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;

use t::shm;
use t::utils;
plan tests => 6;


my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . "/program", args => '1', chdir => $dir->curdir );
is( $dir->stdout,	'1',	'is instrumented program stdout correct' );
is( $dir->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,		0,	'is instrumented program exit code 0' );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $procfile = t::shm->new( $shm_file_path );

is( $procfile->{size},	$t::shm::os_allocsize * 4, 'is file 4 allocation units' );
