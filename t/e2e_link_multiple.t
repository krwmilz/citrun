#
# Check that linking more than one instrumented object file together works.
#
use strict;
use warnings;
use t::utils;
plan tests => 3;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'one.c', <<EOF );
void second_func();

int main(void) {
	second_func();
	return 0;
}
EOF

$wrap->write( 'two.c', <<EOF );
void third_func();

void second_func(void) {
	third_func();
	return;
}
EOF

$wrap->write( 'three.c', <<EOF );
void third_func(void) {
	return;
}
EOF

$wrap->run( args => os_compiler() . 'main one.c two.c three.c', chdir => $wrap->curdir );

my $log_good = <<EOF;
>> citrun_inst
CITRUN_COMPILERS = ''
PATH=''
Found source file ''
Found source file ''
Found source file ''
Link detected, adding '' to command line.
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    7 Lines of source code
    1 Function definitions
    1 Return statement values
    1 Call expressions
    6 Total statements
Modified source written successfully.
Instrumentation of '' finished:
    7 Lines of source code
    1 Function definitions
    1 Call expressions
    5 Total statements
Modified source written successfully.
Instrumentation of '' finished:
    4 Lines of source code
    1 Function definitions
    2 Total statements
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
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
