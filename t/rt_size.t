use strict;
use warnings;
use Test::More tests => 1;
use tlib::program;
use tlib::shm;
#
# Test that the runtime shared file size is what we expect.
#

system("tlib/program/program 1");

my $procfile = tlib::shm->new();
is($procfile->{size}, 16384, "size of memory file");
