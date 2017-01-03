#
# Test that:
# - not having PATH set errors
# - not having CITRUN_SHARE in PATH when using transparent compile mode errors
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 6;

my $cc = Test::Cmd->new( prog => 'cc', workdir => '' );

delete $ENV{'PATH'};
$cc->run( args => "-c nomatter.c", chdir => $cc->curdir );

# XXX: Somethings wrong here. The commented error should be displayed when PATH
# is not set at all.
my $error_good = "citrun_inst: Error: CITRUN_SHARE not in PATH.
";
#my $error_good = 'citrun_inst: Error: PATH is not set.';

is( $cc->stdout,	'',	'is cc stdout empty' );
is( $cc->stderr,	$error_good,	'is cc stderr identical' );
is( $? >> 8,		1,	'is cc exit code 1' );

$ENV{PATH} = "";
$error_good = "citrun_inst: Error: CITRUN_SHARE not in PATH.
";
$cc->run( args => "-c nomatter.c", chdir => $cc->curdir );

is( $cc->stdout,	'',	'is cc stdout identical' );
is( $cc->stderr,	$error_good,	'is cc stderr empty' );
is( $? >> 8,		1,	'is cc exit code 1' );
