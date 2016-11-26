#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use Test::More tests => 13;
use t::program;
use t::shm;
use t::tmpdir;

my $tmp_dir = t::tmpdir->new();
t::program->new($tmp_dir);

my $ret = system("cd $tmp_dir && ./program 1");
is $ret >> 8,	0,	"is program exit code 0";

my @procfiles = glob("$ENV{CITRUN_PROCDIR}/program_*");
is scalar @procfiles,	1,	"is one file in procdir";

my $shm = t::shm->new($procfiles[0]);
is $shm->{magic},	"ctrn",	"is file magic correct";
is $shm->{major},	0,	"is major correct";
is $shm->{minor},	0,	"is minor correct";

my ($pid, $ppid, $pgrp) = @{ $shm->{pids} };
cmp_ok $pid,	'<',	100 * 1000,	"is pid < max pid";
cmp_ok $pid,	'>',	1,		"is pid > min pid";
cmp_ok $ppid,	'<',	100 * 1000,	"is ppid < max pid";
cmp_ok $ppid,	'>',	1,		"is ppid > min pid";
cmp_ok $pgrp,	'<',	100 * 1000,	"is pgrp < max pid";
cmp_ok $pgrp,	'>',	1,		"is pgrp > min pid";

is $shm->{progname},	"program",	"is test program name correct";
like $shm->{cwd},	qr/.*$tmp_dir/,	"is working directory believable";
