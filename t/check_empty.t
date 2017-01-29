#
# Verify the output when 0 citrun.log files are found.
#
use strict;
use warnings;

use Test::Cmd;
use Test::More;

plan skip_all => 'not impl' if ($^O eq "MSWin32");
plan tests => 3;


my $output_good = "Summary:
         0 Source files used as input
";

my $check = Test::Cmd->new( prog => 'bin/citrun_check', workdir => '' );
$check->run( chdir => $check->curdir );

is( $check->stdout,	$output_good,	'is citrun_check stdout identical' );
is( $check->stderr,	'',	'is citrun_check stderr empty' );
is( $? >> 8,		123,	'is citrun_check exit code 123' );
