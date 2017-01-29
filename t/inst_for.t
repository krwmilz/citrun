#
# Test that for loop condition instrumenting works.
#
use strict;
use warnings;

use t::utils;
plan tests => 4;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );
$inst->write( 'for.c', <<EOF );
int main(int argc, char *argv[]) {
	for (;;);

	for (argc = 0; argc < 10; argc++)
		argv++;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int main(int argc, char *argv[]) {++_citrun.data[0];
	for (;;);

	for ((++_citrun.data[3], argc = 0); (++_citrun.data[3], (++_citrun.data[3], argc < 10)); argc++)
		argv++;
}
EOF

my $check_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    7 Lines of source code
    1 Function definitions
    1 For loops
    15 Total statements
    2 Binary operators
Modified source written successfully.
EOF

# Run the command.
$inst->run( args => '-c for.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'for.c');

# Sanitize paths from stdout.
my $check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 } ;
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
