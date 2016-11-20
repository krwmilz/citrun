#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;
use POSIX;
use Test::More tests => 2;
use t::program;
use t::shm;
use t::tmpdir;

my $tmp_dir = t::tmpdir->new();
t::program->new($tmp_dir);

my $ret = system("$tmp_dir/program 1");
is $ret >> 8,	0,	"is test program exit code 0";

my $procfile = t::shm->new($tmp_dir);

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);
is($procfile->{size}, $pagesize * 4, "is memory file 4 pages long");
