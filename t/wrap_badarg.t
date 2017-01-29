#
# Make sure calling citrun_wrap with arguments fails.
#
use strict;
use warnings;

use Test::Cmd;
use Test::More tests => 3;


my $wrap = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );
$wrap->run( args => '-ASD', chdir => $wrap->curdir );

my $err_good;
if ($^O eq "MSWin32") {
	$err_good = "'-ASD' is not recognized as an internal or external command";
} else {
	$err_good = '-ASD: not found';
}

is( $wrap->stdout,	'',	'is citrun_wrap stdout silent' );
like( $wrap->stderr,	qr/$err_good/, 'is citrun_wrap stderr looking good' );
isnt( $? >> 8,		0,	'is citrun_wrap exit code nonzero' );
