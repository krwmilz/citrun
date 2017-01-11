#
# Check that two source files given on the same command line both get
# instrumented fully.
#
use strict;
use warnings;
use t::utils;
plan tests => 3;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->write( 'other.c', <<EOF );
int other(void) {
	return 0;
}
EOF

$wrap->run( args => os_compiler() . 'main main.c other.c', chdir => $wrap->curdir );

my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Found source file ''
Link detected, adding '' to command line.
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    1 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Instrumentation of '' finished:
    4 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
Restored ''
EOF

my $citrun_log;
$wrap->read( \$citrun_log, 'citrun.log' );
$citrun_log = clean_citrun_log($citrun_log);

eq_or_diff( $citrun_log,	$log_good,	'is citrun.log identical', { context => 3 } );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap stderr silent' );
is( $? >> 8,	0,		'is citrun_wrap exit code 0' );
