#
# Make sure that citrun_wrap exits with the same code as the native build.
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 3;

my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

my $err_good;
if ($^O eq "MSWin32") {
	$wrap->run( args => 'more.com asdf' );
	$err_good = 'Cannot access file .*asdf';
}
else {
	$wrap->run( args => 'ls asdf' );
	$err_good = "ls: asdf: No such file or directory";
}

is( $wrap->stdout,	'',	'is citrun_wrap stdout empty');
like( $wrap->stderr,	qr/$err_good/,	'is citrun_wrap stderr identical');
is( $? >> 8,		1,	'is citrun_wrap exit code 1');
