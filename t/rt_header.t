#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use Test::More tests => 14;
use tlib::program;
use tlib::shm;

my $ret = system('tlib/program/program 1');
is $ret >> 8,	0,	"is program exit code 0";

my $shm = tlib::shm->new();
is $shm->{major}, 0, "is major correct";
is $shm->{minor}, 0, "is minor correct";

my ($pid, $ppid, $pgrp) = @{ $shm->{pids} };
cmp_ok $pid,	'<',	100 * 1000,	"pid is less than max pid";
cmp_ok $pid,	'>',	0,	"pid is greater than min pid";
cmp_ok $ppid,	'<',	100 * 1000,	"ppid is less than max pid";
cmp_ok $ppid,	'>',	0,	"ppid is greater than min pid";
cmp_ok $pgrp,	'<',	100 * 1000,	"pgrp is less than max pid";
cmp_ok $pgrp,	'>',	0,	"pgrp is greater than min pid";

cmp_ok $shm->{prg_sz},	'<',	1024,	'is size of program name less than 1024';
cmp_ok $shm->{prg_sz},	'>',	0,	'is size of program name greater than 0';
is $shm->{progname},	"program",	'is test program name correct';

cmp_ok $shm->{cwd_sz},	'<',	1024,	'is size of working dir less than 1024';
cmp_ok $shm->{cwd_sz},	'>',	0,	'is size of working dir greater than 0';
# is $cwd,	"/home/...",	'is working directory believable';
