#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use Test::More tests => 11;
use t::program;
use t::shm;

my $ret = system('t/program/program 1');
is $ret >> 8,	0,	"is program exit code 0";

my $shm = t::shm->new();
is $shm->{magic}, "citrun", "is file magic correct";
is $shm->{major}, 0, "is major correct";
is $shm->{minor}, 0, "is minor correct";

my ($pid, $ppid, $pgrp) = @{ $shm->{pids} };
cmp_ok $pid,	'<',	100 * 1000,	"pid is less than max pid";
cmp_ok $pid,	'>',	0,	"pid is greater than min pid";
cmp_ok $ppid,	'<',	100 * 1000,	"ppid is less than max pid";
cmp_ok $ppid,	'>',	0,	"ppid is greater than min pid";
cmp_ok $pgrp,	'<',	100 * 1000,	"pgrp is less than max pid";
cmp_ok $pgrp,	'>',	0,	"pgrp is greater than min pid";

is $shm->{progname},	"program",	'is test program name correct';
# is $cwd,	"/home/...",	'is working directory believable';
