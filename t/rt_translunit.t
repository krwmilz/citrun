#
# Test that the shared memory translation units are what we expect.
#
use strict;
use warnings;
use POSIX;
use Test::Cmd;
use Test::More tests => 7;
use test::program;
use test::shm;

my $test_prog = Test::Cmd->new( prog => 'test/program/program', workdir => '');
$test_prog->run( args => "10" );
is $? >> 8,	0,	'is test program exit code 0';

my $shm = test::shm->new();

my ($tu1, $tu2, $tu3) = @{ $shm->{translation_units} };
is	$tu1->{size},	9,	"is transl unit 1 9 lines";
cmp_ok	$tu1->{cmp_sz},	'<',	1024,	'is size of compiler file name less than 1024';
cmp_ok	$tu1->{cmp_sz},	'>',	0,	'is size of compiler file name greater than 0';
#is	$tu1->{comp_file_name},	'three.c',	'is compiler file name right';
cmp_ok	$tu1->{abs_sz},	'<',	1024,	'is size of absolute file path less than 1024';
cmp_ok	$tu1->{abs_sz},	'>',	0,	'is size of absolute file path greater than 0';
like	$tu1->{abs_file_path},	qr/.*three.c/,	'is absolute file path believable';
