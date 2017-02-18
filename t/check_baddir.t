#
# Verify that passing a bad directory to citrun_check errors out.
#
use Modern::Perl;
use Test::Cmd;
use Test::More;

plan skip_all => 'not impl on win32' if ($^O eq "MSWin32");
plan tests => 3;


my $output_good = "Summary:
         0 Source files used as input
";
my $error_good = "find: _nonexistent_: No such file or directory
";

my $check = Test::Cmd->new( prog => 'bin/citrun_check', workdir => '' );
$check->run( args => '_nonexistent_', chdir => $check->curdir );

is( $check->stdout,	$output_good,	'is citrun_check stdout identical' );
is( $check->stderr,	$error_good,	'is citrun_check stderr identical' );
is( $? >> 8,		123,	'is citrun_check exit code 123' );
