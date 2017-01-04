#
# Make sure calling citrun_wrap with arguments fails.
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 3;

my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );
$wrap->run( args => '-ASD', chdir => $wrap->curdir );

my $err_good;
if ($^O eq "MSWin32") {
	$err_good = "'-ASD' is not recognized as an internal or external command,
operable program or batch file.
";
}

is( $wrap->stdout,	'',	'is citrun_wrap stdout silent' );
is( $wrap->stderr,	$err_good, 'is citrun_wrap stderr identical' );
is( $? >> 8,		1,	'is citrun_wrap exit code 1' );
#output_good="usage: citrun_wrap <build cmd>"
#ok_program "citrun_wrap -ASD" 1 "$output_good" citrun_wrap -ASD
