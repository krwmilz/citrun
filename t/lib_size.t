#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;
use File::DosGlob 'glob';
use POSIX;
use t::utils;
plan tests => 5;


my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . "/program", args => '1', chdir => $dir->curdir );
is( $? >> 8,		0,	"is instrumented program exit code 0" );

my @procfiles = glob("$ENV{CITRUN_PROCDIR}/program_*");
is scalar @procfiles,	1,	"is one file in procdir";

my $procfile = t::shm->new($procfiles[0]);

my $alloc_size;
if ($^O eq "MSWin32") {
	# Windows allocation granularity.
	$alloc_size = 64 * 1024;
} else {
	$alloc_size = POSIX::sysconf(POSIX::_SC_PAGESIZE);
}

is( $procfile->{size},	$alloc_size * 4, "is file 4 allocation units long" );
