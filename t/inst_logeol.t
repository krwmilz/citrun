#
# Check that proper platform specific line endings exist in citrun.log.
#
use Modern::Perl;
use t::utils;
plan tests => 1;


my $wrap = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

$wrap->write( 'main.c', <<EOF );
EOF

$wrap->run( args => os_compiler() . 'main main.c', chdir => $wrap->curdir );

# Read log file in binary mode so \r\n's don't get converted by the IO layer.
open( my $fh, '<', File::Spec->catfile( $wrap->workdir, 'citrun.log' ) );
binmode( $fh );
read $fh, my $citrun_log, 64 * 1024;

# Check line endings.
if ($^O eq 'MSWin32') {
	# Windows has extra lines because exec() is emulated by fork().

	my $rn_count = () = $citrun_log =~ /\r\n/g;
	is( $rn_count,	15,	'is \r\n count correct' );
}
else {
	my $n_count = () = $citrun_log =~ /\n/g;
	is( $n_count,	14,	'is \n count correct' );
}
