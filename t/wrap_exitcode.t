#
# Make sure that citrun_wrap exits with the same code as the native build.
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 3;

my $wrap = Test::Cmd->new( prog => 'src/citrun_wrap', workdir => '' );

if ($^O eq "MSWin32") {
	my $err_good = "Cannot access file C:\\Users\\kyle\\citrun\\asdf
";
	$wrap->run( args => 'more.com asdf' );

	is( $wrap->stdout,	'',	'is citrun_wrap stdout empty');
	is( $wrap->stderr,	$err_good,	'is citrun_wrap stderr identical');
	is( $? >> 8,		1,	'is citrun_wrap exit code 1');
}
else {
	$wrap->run( args => 'ls asdf' );
	my $err_good = "ls: asdf: No such file or directory
";

	is( $wrap->stdout,	'',	'is citrun_wrap stdout empty');
	is( $wrap->stderr,	$err_good,	'is citrun_wrap stderr identical');
	is( $? >> 8,		1,	'is citrun_wrap exit code 1');
}
