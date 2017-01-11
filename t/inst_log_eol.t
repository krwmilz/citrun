#
# Test that citrun.log has the correct line endings for the platform its on.
#
use strict;
use warnings;
use t::utils;
plan tests => 3;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', <<EOF );
int
main(void)
{
	return 0;
}
EOF

$wrap->write( 'Jamfile', 'Main main : main.c ;' );

$wrap->run( args => 'jam', chdir => $wrap->curdir );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap exit code 0' );

my $citrun_log;
$wrap->read(\$citrun_log, 'citrun.log');

if ($^O eq 'MSWin32') {
	my $rn_count = () = $citrun_log =~ /\n/g;
	is( $rn_count,	24,	'is \r\n count correct' );
}
else {
	my $n_count = () = $citrun_log =~ /\n/g;
	is( $n_count,	24,	'is \n count correct' );
}
