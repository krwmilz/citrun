#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use Test::More tests => 12;
use t::program;
use t::shm;
use t::tmpdir;

my $tmp_dir = t::tmpdir->new();
t::program->new($tmp_dir);

my $ret = system("cd $tmp_dir && program 1");
is $ret >> 8,	0,	"is program exit code 0";

my $shm = t::shm->new($tmp_dir);
is $shm->{magic}, "ctrn", "is file magic correct";
is $shm->{major}, 0, "is major correct";
is $shm->{minor}, 0, "is minor correct";

my ($pid, $ppid, $pgrp) = @{ $shm->{pids} };
cmp_ok $pid,	'<',	100 * 1000,	"pid is less than max pid";
cmp_ok $pid,	'>',	1,	"pid is greater than min pid";
cmp_ok $ppid,	'<',	100 * 1000,	"ppid is less than max pid";
cmp_ok $ppid,	'>',	1,	"ppid is greater than min pid";
cmp_ok $pgrp,	'<',	100 * 1000,	"pgrp is less than max pid";
cmp_ok $pgrp,	'>',	1,	"pgrp is greater than min pid";

is $shm->{progname},	"program",	'is test program name correct';
is $shm->{cwd},		$tmp_dir,	'is working directory believable';
