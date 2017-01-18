#
# Check that giving citrun_wrap a compile command with a non existent file is
# handled.
#
use strict;
use warnings;

use t::utils;
plan tests => 4;


my $inst = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
EOF

my $err_good = 'citrun_inst: stat: No such file or directory';

$inst->run( args => 'cc -c doesnt_exist.c', chdir => $inst->curdir );

my $out;
$inst->read( \$out, 'citrun.log' );
$out = clean_citrun_log($out);
eq_or_diff( $out,	$out_good,	'is citrun_wrap output identical' );

is( $inst->stdout,	'',		'is citrun_wrap stdout silent' );
like( $inst->stderr,	qr/$err_good/,	'is citrun_wrap stderr silent' );
is( $? >> 8,		1,		'is citrun_wrap exit code 1' );
