#
# Check that a raw citrun.log file is in good shape.
# citrun_check relies on this output, and citrun_check is used quite a bit.
#
use strict;
use warnings;

use t::utils;
plan tests => 3;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', <<EOF );
#include <stdlib.h>

long long
fibonacci(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fibonacci(n - 1) + fibonacci(n - 2);
}

int
main(int argc, char *argv[])
{
	long long n;

	n = atoi(argv[1]);
	return fibonacci(n);
}
EOF

$wrap->write( 'Jamfile', 'Main main : main.c ;' );
$wrap->run( args => 'jam', chdir => $wrap->curdir );

my $citrun_log_good =<<EOF ;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    22 Lines of source code
    2 Function definitions
    2 If statements
    4 Return statement values
    4 Call expressions
    58 Total statements
    6 Binary operators
Modified source written successfully.
Forked compiler ''
Rewritten source compile successful
Restored ''
>> citrun_inst
Compilers path = ''
PATH = ''
Link detected, adding '' to command line.
Command line is ''
No source files found on command line.
EOF

my $citrun_log;
$wrap->read(\$citrun_log, 'citrun.log');

if ($^O eq 'MSWin32') {
	# Windows gets an extra message because exec() is emulated by fork().
	$citrun_log_good .= <<EOF ;
Forked compiler ''
EOF
}

$citrun_log = clean_citrun_log($citrun_log);

eq_or_diff( $citrun_log, $citrun_log_good, 'is citrun.log file identical', { context => 3 } );
# Deliberately not checking $wrap->stdout here because portability.
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap exit code 0' );
