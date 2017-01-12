#
# Test that a ran program outputs a memory file with correct line execution
# counts.
#
use strict;
use warnings;

use t::mem;
use t::utils;
plan tests => 8;


my $dir = setup_projdir();

$dir->run( prog => $dir->workdir . '/program', args => '10', chdir => $dir->curdir );
is( $dir->stdout,	'55',	'is instrumented program stdout correct' );
is( $dir->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,	0,	"is instrumented program exit code 0" );

my $shm_file_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $shm = t::mem->new( $shm_file_path );

my %tus = %{ $shm->{trans_units} };
my ($tu1, $tu2, $tu3) = sort keys %tus;

# Diff format test chosen here because these numbers are related to source code.
my @fib_good = qw(
177
177
177
354
34
286
55
0
528
0
0
);

my @main_good = qw(
0
0
0
0
0
0
1
1
1
0
0
2
0
0
0
0
2
0
2
1
0
0
);

my @print_good = qw(
0
0
1
1
1
1
0
0
0
);

eq_or_diff( $shm->get_buffers($tu1), \@fib_good, 'is fib count identical', { context => 3 } );
eq_or_diff( $shm->get_buffers($tu2), \@main_good, 'is main count identical', { context => 3 } );
eq_or_diff( $shm->get_buffers($tu3), \@print_good, 'is print count identical', { context => 3 } );
