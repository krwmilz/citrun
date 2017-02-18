#
# Check that opening the viewer after an instrumented program has exited gives
# an identical output to known good.
#
use File::Compare;
use Imager;
use Modern::Perl;
use t::utils;

plan tests => 6;

my $dir = setup_projdir();

$ENV{CITRUN_PROCDIR} =  $dir->workdir . "/procdir/";
$dir->run( prog => $dir->workdir . "/program", args => '1', chdir => $dir->curdir );
is( $dir->stdout,	'1',	'is instrumented program stdout correct' );
is( $dir->stderr,	'',	'is instrumented program stderr silent' );

my $render_file = File::Spec->catdir( $dir->workdir, 'test.tga' );
my $render_good_file = File::Spec->catfile( 't', 'gl_basic.tga' );

$dir->run( prog => 'bin/citrun_gltest', args => "$render_file 800 600", workdir => '' );
print $dir->stdout;
is( $dir->stderr,	'',	'is citrun_gltest stderr silent' );

if (compare( $render_file, $render_good_file ) == 0) {
	pass( 'is render file identical' );
}
else {
	my $render = Imager->new( file => $render_file ) or die Imager->errstr();
	my $render_good = Imager->new( file => 't/gl_basic.tga' ) or die Imager->errstr();

	my $diff = $render->difference( other => $render_good );
	$diff->write( file => $dir->workdir . "/diff.tga" ) or die Imager->errstr;

	system("imlib2_view " . $dir->workdir . "/diff.tga" );
	fail( 'is render file identical' );
}
