#
# Test that:
# - TODO: not having PATH set errors
# - not having CITRUN_PATH set when using transparent compile mode errors
#
use strict;
use warnings;

use t::utils;
plan tests => 4;


my $compiler = 'compilers/cc';
$compiler = 'compilers\cl' if ($^O eq 'MSWin32');

my $cc = Test::Cmd->new( prog => $compiler, workdir => '' );

my $error_good = "Error: '.*compilers' not in PATH.";

$cc->run( args => '', chdir => $cc->curdir );
is( $cc->stdout,	'',			'is cc stdout empty' );
like( $cc->stderr,	qr/$error_good/,	'is cc stderr identical' );
is( $? >> 8,		1,			'is cc exit code 1' );

my $log_out;
$cc->read( \$log_out, 'citrun.log' );

my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Error: '' not in PATH.
EOF

eq_or_diff( clean_citrun_log( $log_out ), $log_good,	'is citrun.log identical' );
