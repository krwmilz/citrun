#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 14;
use test::utils;

$ENV{CITRUN_TOOLS} = 1;
my $test_prog = Test::Cmd->new( prog => 'test/program', workdir => '');
$test_prog->run( args => "1" );
is $? >> 8,	0,	'did test program exit 0';

open(my $fh, "<:mmap", "procfile.shm") or die $!;

my ($major, $minor) = unpack("C2", test::utils::xread($fh, 2));
is $major, 0, "is major correct";
is $minor, 0, "is minor correct";

my ($pid, $ppid, $pgrp) = unpack("L3", test::utils::xread($fh, 12));
cmp_ok $pid,	'<',	100 * 1000,	"pid is less than max pid";
cmp_ok $pid,	'>',	0,	"pid is greater than min pid";
cmp_ok $ppid,	'<',	100 * 1000,	"ppid is less than max pid";
cmp_ok $ppid,	'>',	0,	"ppid is greater than min pid";
cmp_ok $pgrp,	'<',	100 * 1000,	"pgrp is less than max pid";
cmp_ok $pgrp,	'>',	0,	"pgrp is greater than min pid";

my ($prg_sz) = unpack("S", test::utils::xread($fh, 2));
cmp_ok $prg_sz,	'<',	1024,	'is size of program name less than 1024';
cmp_ok $prg_sz,	'>',	0,	'is size of program name greater than 0';
my ($progname) = unpack("Z$prg_sz", test::utils::xread($fh, $prg_sz));
is $progname,	"program",	'is test program name correct';

my ($cwd_sz) = unpack("S", test::utils::xread($fh, 2));
cmp_ok $cwd_sz,	'<',	1024,	'is size of working dir less than 1024';
cmp_ok $cwd_sz,	'>',	0,	'is size of working dir greater than 0';
my ($cwd) = unpack("Z$cwd_sz", test::utils::xread($fh, $cwd_sz));
# is $cwd,	"/home/...",	'is working directory believable';
