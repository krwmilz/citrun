#
# Check that opening the viewer after an instrumented program has exited gives
# an identical output to known good.
#
use Modern::Perl;

use t::gl_utils;
use t::utils;
plan tests => 9;


my $dir = setup_projdir();
$ENV{CITRUN_PROCDIR} =  $dir->workdir . "/procdir/";

# Run instrumented program.
$dir->run( prog => $dir->workdir . "/program", args => '1', chdir => $dir->curdir );
is( $dir->stdout,	'1',	'is instrumented program stdout correct' );
is( $dir->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,		0,	'is instrumented program exit code zero' );

my $output_file = File::Spec->catdir( $dir->workdir, 'test.tga' );
my $output_good = File::Spec->catfile( 't', 'gl', 'basic.tga' );

my $gltest = Test::Cmd->new( prog => 'bin/citrun_gltest', workdir => '' );
$gltest->run( args => "$output_file 800 600" );
isnt( $gltest->stdout,	'',	'is citrun_gltest stdout not silent' );
is( $gltest->stderr,	'',	'is citrun_gltest stderr silent' );
is( $? >> 8,		0,	'is citrun_gltest exit code zero' );

ok_image( $output_file, $output_good, $gltest->workdir );
