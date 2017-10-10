#
# Check that citrun_gl outputs a good error message when $CITRUN_PROCDIR is bad.
#
use Modern::Perl;

use t::utils;
plan tests => 3;


my $gl = Test::Cmd->new( prog => 'bin/citrun_gl', workdir => '' );

my $procdir = $gl->workdir . "/procdir/";
$ENV{CITRUN_PROCDIR} =  $procdir;

# Create a file in the exact place the directory is supposed to be.
$gl->write( 'procdir', '' );
$gl->run();

my $err_good = "citrun_gl: opendir '$procdir': Not a directory";
is( $gl->stdout,	'',		'is stdout silent' );
like( $gl->stderr,	qr/$err_good/,	'is stderr silent' );
is( $? >> 8,		1,		'is exit code nonzero' );
