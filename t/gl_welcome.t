#
# Checks that opening the viewer without any runtime files shows the welcome
# message.
#
use Modern::Perl;

use t::gl_utils;
use t::utils;
plan tests => 4;


my $gltest = Test::Cmd->new( prog => 'bin/citrun_gltest', workdir => '' );
$ENV{CITRUN_PROCDIR} =  $gltest->workdir . "/procdir/";

my $output_file = File::Spec->catdir( $gltest->workdir, 'test.tga' );
my $output_good = File::Spec->catfile( 't', 'gl', 'welcome.tga' );

$gltest->run( args => "$output_file 800 600" );
isnt( $gltest->stdout,	'',	'is citrun_gltest stdout not silent' );
is( $gltest->stderr,	'',	'is citrun_gltest stderr silent' );
is( $? >> 8,		0,	'is citrun_gltest exit code zero' );

ok_image( $output_file, $output_good, $gltest->workdir );
