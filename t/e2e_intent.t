#
# Make sure the intention of a program isn't altered by instrumentation.
# Show this by getting correct results from an instrumented program.
#
use strict;
use warnings;
use t::utils;
plan tests => 11;

my $e2e = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$e2e->write( 'fib.c', <<EOF );
#include <stdio.h>
#include <stdlib.h>

int fibonacci(int n) {
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int main(int argc, char *argv[]) {
	int n;

	if (argc != 2)
		return 1;

	n = atoi(argv[1]);
	printf("%i", fibonacci(n));

	return 0;
}
EOF

$e2e->run( args => os_compiler() . 'fib fib.c', chdir => $e2e->curdir );

my $log;
$e2e->read( \$log, 'citrun.log' );
$log = clean_citrun_log( $log );

my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Link detected, adding '' to command line.
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    24 Lines of source code
    2 Function definitions
    3 If statements
    5 Return statement values
    5 Call expressions
    64 Total statements
    7 Binary operators
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
EOF

print $e2e->stdout;
is( $e2e->stderr,	'',	'is citrun_wrap compile stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap compile exit code 0' );
eq_or_diff( $log,	$log_good,	'is citrun_wrap log file identical' );

$e2e->run( prog => $e2e->workdir . "/fib", chdir => $e2e->curdir );
is( $e2e->stderr,	'',	'is fib stderr silent' );
is( $? >> 8,		1,	'is fib with no args exit 1' );

$e2e->run( prog => $e2e->workdir . "/fib", args => '10', chdir => $e2e->curdir );
is( $e2e->stdout,	'55',	'is fib 10 equal to 55' );
is( $e2e->stderr,	'',	'is fib 10 stderr silent' );
is( $? >> 8,		0,	'is fib 10 exit 0' );

$e2e->run( prog => $e2e->workdir . "/fib", args => '20', chdir => $e2e->curdir );
is( $e2e->stdout,	'6765',	'is fib 20 equal to 6765' );
is( $e2e->stderr,	'',	'is fib 20 stderr silent' );
is( $? >> 8,		0,	'is fib 20 exit 0' );
