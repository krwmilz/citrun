#
# Test that the shared memory translation units are what we expect.
#
use strict;
use warnings;
use POSIX;
use Test::Cmd;
use Test::More tests => 7;
use test::utils;

$ENV{CITRUN_TOOLS} = 1;
my $test_prog = Test::Cmd->new( prog => 'test/program', workdir => '');
$test_prog->run( args => "10" );
is $? >> 8,	0,	'did test program exit 0';

open(my $fh, "<:mmap", "procfile.shm");

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);
test::utils::xread($fh, $pagesize);

my ($size) = unpack("L", test::utils::xread($fh, 4));
is $size,	9,	'is line buffer size 100';

my ($cmp_sz) = unpack("S", test::utils::xread($fh, 2));
cmp_ok $cmp_sz,	'<',	1024,	'is size of compiler file name less than 1024';
cmp_ok $cmp_sz,	'>',	0,	'is size of compiler file name greater than 0';
my $comp_file_name = test::utils::xread($fh, $cmp_sz);
#is $comp_file_name,	'three.c',	'is compiler file name right';

my ($abs_sz) = unpack("S", test::utils::xread($fh, 2));
cmp_ok $abs_sz,	'<',	1024,	'is size of absolute file path less than 1024';
cmp_ok $abs_sz,	'>',	0,	'is size of absolute file path greater than 0';
my $abs_file_path = test::utils::xread($fh, $abs_sz);
like $abs_file_path,	qr/.*three.c/,	'is absolute file path believable';
