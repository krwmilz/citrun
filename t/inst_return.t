#
# Check that return statement values (if any) are instrumented correctly.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'src/citrun_inst', workdir => '' );
$inst->write( 'return.c', <<EOF );
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int foo() {++_citrun.data[0];
	return (++_citrun.data[1], 0);
}

int main(void) {++_citrun.data[4];
	return (++_citrun.data[5], 10);

	return (++_citrun.data[7], (++_citrun.data[7], 10 + 10));

	return (++_citrun.data[9], (++_citrun.data[9], foo()));
}
EOF

my $check_good = <<EOF;
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    12 Lines of source code
    2 Function definitions
    4 Return statement values
    1 Call expressions
    14 Total statements
    1 Binary operators
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c return.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'return.c');

# Sanitize paths from stdout.
my $check_out = $inst->stdout;
$check_out =~ s/^.*Milliseconds spent.*\n//gm;
$check_out =~ s/'.*'/''/gm;
$check_out =~ s/\(.*\)/\(\)/gm;
$check_out =~ s/^[0-9]+: //gm;

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_good,	$check_out, 'is citrun_inst output identical';
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
