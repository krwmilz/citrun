#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;
use POSIX;
use Test::More tests => 3;
use t::utils;

my $tmp_dir = t::tmpdir->new();

my $ret = system("$tmp_dir/program 1");
is $ret >> 8,		0,	"is test program exit code 0";

my @procfiles = glob("$ENV{CITRUN_PROCDIR}/program_*");
is scalar @procfiles,	1,	"is one file in procdir";

my $procfile = t::shm->new($procfiles[0]);

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);
is($procfile->{size},	$pagesize * 4,	"is memory file 4 pages long");
