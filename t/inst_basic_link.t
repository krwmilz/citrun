#
# Check that the most basic of compile command lines works.
#
use strict;
use warnings;
use t::utils;
plan tests => 3;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->run( args => os_compiler() . 'main main.c', chdir => $wrap->curdir );

my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Link detected, adding '' to command line.
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    1 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
EOF

my $citrun_log;
$wrap->read( \$citrun_log, 'citrun.log' );
$citrun_log = clean_citrun_log($citrun_log);

eq_or_diff( $citrun_log, $log_good, 'is citrun.log file identical', { context => 3 } );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap stderr empty' );
is( $? >> 8,		0,	'is citrun_wrap exit code 0' );
