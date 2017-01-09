#
# Test that:
# - TODO: not having PATH set errors
# - not having CITRUN_PATH set when using transparent compile mode errors
#
use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 3;


my $cc = Test::Cmd->new( prog => 'compilers/cc', workdir => '' );

my $error_good = "Error: compilers not in PATH.
";

$cc->run( args => '', chdir => $cc->curdir );
is( $cc->stdout,	'',	'is cc stdout empty' );
is( $cc->stderr,	$error_good,	'is cc stderr identical' );
is( $? >> 8,		1,	'is cc exit code 1' );
