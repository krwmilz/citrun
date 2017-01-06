#
# Test that the shared memory translation units are what we expect.
#
use strict;
use warnings;
use t::utils;
plan tests => 8;

my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . '/program', args => '1', chdir => $dir->curdir );
is( $? >> 8,	0,	"is instrumented program exit code 0" );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $shm = t::shm->new( $shm_file_path );

my ($tu1, $tu2, $tu3) = @{ $shm->{translation_units} };
is	$tu1->{size},	9,	"is translation unit 1 9 lines";
is	$tu1->{comp_file_name},	'print.c',	'is compiler file name right';
like	$tu1->{abs_file_path},	qr/.*print.c/,	'is absolute file path believable';

is	$tu2->{size},	11,	"is translation unit 2 9 lines";
is	$tu2->{comp_file_name},	'fib.c',	'is compiler file name right';
like	$tu2->{abs_file_path},	qr/.*fib.c/,	'is absolute file path believable';
