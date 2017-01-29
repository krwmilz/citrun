#
# Check that really long function declarations are instrumented properly.
#
use strict;
use warnings;

use t::utils;
plan tests => 4;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );
$inst->write( 'funcdef.c', <<EOF );
void

other(int a,
	int b)


{
}
EOF

# Known good output.
my $inst_good = <<EOF ;
void

other(int a,
	int b)


{++_citrun.data[0];++_citrun.data[1];++_citrun.data[2];++_citrun.data[3];++_citrun.data[4];++_citrun.data[5];++_citrun.data[6];
}
EOF

my $check_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    9 Lines of source code
    1 Function definitions
    1 Total statements
Modified source written successfully.
EOF

# Run the command.
$inst->run( args => '-c funcdef.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'funcdef.c');

# Sanitize paths from stdout.
my $check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 };
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
