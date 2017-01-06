#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;
use POSIX;
use t::utils;
plan tests => 4;


my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . "/program", args => '1', chdir => $dir->curdir );
is( $? >> 8,		0,	"is instrumented program exit code 0" );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $procfile = t::shm->new( $shm_file_path );

my $alloc_size;
if ($^O eq "MSWin32") {
	# Windows allocation granularity.
	$alloc_size = 64 * 1024;
} else {
	$alloc_size = POSIX::sysconf(POSIX::_SC_PAGESIZE);
}

is( $procfile->{size},	$alloc_size * 4, "is file 4 allocation units long" );
