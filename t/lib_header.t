#
# Test that the shared memory header is what we expect.
#
use strict;
use warnings;
use t::shm;
use t::utils;
plan tests => 17;

my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . '/program', args => '1', chdir => $dir->curdir );
is( $? >> 8,	0,	"is instrumented program exit code 0" );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $shm = t::shm->new( $shm_file_path );

is $shm->{magic},	"ctrn",	"is correct file magic";
is $shm->{major},	0,	"is correct major";
is $shm->{minor},	0,	"is correct minor";
is $shm->{units},	3,	"is correct number of translation units";
is $shm->{loc},		42,	"is loc right ";
is $shm->{done},	1,	"is done signalled";

my ($pid, $ppid, $pgrp) = @{ $shm->{pids} };
cmp_ok $pid,	'<',	100 * 1000,	"is pid < max pid";
cmp_ok $pid,	'>',	1,		"is pid > min pid";

SKIP: {
	skip 'win32 has no ppid or pgrp', 4 if ($^O eq "MSWin32");

	cmp_ok $ppid,	'<',	100 * 1000,	"is ppid < max pid";
	cmp_ok $ppid,	'>',	1,		"is ppid > min pid";
	cmp_ok $pgrp,	'<',	100 * 1000,	"is pgrp < max pid";
	cmp_ok $pgrp,	'>',	1,		"is pgrp > min pid";
}

my $tmp_dir = $dir->workdir;
# Regex doesn't like single '\'s, so replace each with two.
$tmp_dir =~ s/\\/\\\\/g;

like( $shm->{cwd},	qr/.*$tmp_dir/,	"is working directory believable" );
like( $shm->{progname},	qr/program/,	"is test program name correct" );
