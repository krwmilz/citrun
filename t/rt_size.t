use strict;
use warnings;
use Test::More tests => 1;
use test::shm;
#
# Test that the runtime shared file size is what we expect.
#

system("test/program 1");

my $procfile = test::shm->new();
is($procfile->{size}, 16384, "size of memory file");
