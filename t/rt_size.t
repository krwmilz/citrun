#
# Test that the runtime shared file size is what we expect.
#
use strict;
use warnings;
use POSIX;
use Test::More tests => 1;
use tlib::program;
use t::shm;

system("tlib/program/program 1");

my $procfile = t::shm->new();

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);
is($procfile->{size}, $pagesize * 4, "is memory file 4 pages long");
