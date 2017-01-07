#
# Test that the shared memory translation units are what we expect.
#
use strict;
use warnings;
use t::utils;
plan tests => 14;

my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . '/program', args => '1', chdir => $dir->curdir );
is( $dir->stdout,	'1',	'is instrumented program stdout correct' );
is( $dir->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,	0,	"is instrumented program exit code 0" );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $shm = t::shm->new( $shm_file_path );

my %tus = %{ $shm->{trans_units} };
my ($tu1, $tu2, $tu3) = sort keys %tus;

like( $tu1,		qr/.*ib.c/,	'is end of absolute file path fib.c' );
is( $tus{$tu1}->{size},	11,		"is fib.c the correct length" );
is( $tus{$tu1}->{comp_file_name}, 'fib.c', 'is compiler file name right' );

like( $tu2,		qr/.*main.c/,	'is end of absolute file path main.c' );
is( $tus{$tu2}->{size},	22,		"is main.c the correct length" );
is( $tus{$tu2}->{comp_file_name}, 'main.c', 'is compiler file name main.c' );

like( $tu3,		qr/.*print.c/,	'is end of absolute file path print.c' );
is( $tus{$tu3}->{size},	9,		"is print.c the correct length" );
is( $tus{$tu3}->{comp_file_name}, 'print.c', 'is compiler file name print.c' );
