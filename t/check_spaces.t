#
# Verify citrun_check can handle paths with spaces when counting log files.
#
use Modern::Perl;
use Test::Cmd;
use Test::More;

plan skip_all => 'not impl on win32' if ($^O eq "MSWin32");
plan tests => 3;


my $output_good = "Summary:
         0 Source files used as input
";

my $check = Test::Cmd->new( prog => 'bin/citrun_check', workdir => '' );

mkdir File::Spec->catdir( $check->workdir, 'dir a' );
mkdir File::Spec->catdir( $check->workdir, 'dir b' );
$check->write( [ 'dir a', 'citrun.log' ], '' );
$check->write( [ 'dir b', 'citrun.log' ], '' );

$check->run( args => '', chdir => $check->curdir );
is( $check->stdout,	$output_good,	'is citrun_check stdout identical' );
is( $check->stderr,	'',	'is citrun_check stderr identical' );
is( $? >> 8,		123,	'is citrun_check exit code 123' );
