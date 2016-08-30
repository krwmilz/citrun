use strict;
use warnings;
use Test::More tests => 1;

#
# Test that the runtime shared file size is what we expect.
#
$ENV{CITRUN_TOOLS} = 1;
system("test/program/program 1");

is((stat "procfile.shm")[7], 16384, "size of memory file");
