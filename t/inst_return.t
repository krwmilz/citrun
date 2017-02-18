#
# Check that return statement values (if any) are instrumented correctly.
#
use Modern::Perl;
use t::utils;
plan tests => 4;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );
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
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    12 Lines of source code
    2 Function definitions
    4 Return statement values
    1 Call expressions
    14 Total statements
    1 Binary operators
Modified source written successfully.
EOF

# Run the command.
$inst->run( args => '-c return.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'return.c');

# Sanitize paths from stdout.
my $check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 };
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
