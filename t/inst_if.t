#
# Check that if statement conditions are instrumented properly.
#
use Modern::Perl;
use t::utils;
plan tests => 4;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );
$inst->write( 'if.c', <<EOF );
int main(int argc, char *argv[]) {
	if (argc == 1)
		return 1;
	else
		return(14);

	if ((argc = 2))
		return 5;
	else
		return(0);
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int main(int argc, char *argv[]) {++_citrun.data[0];
	if ((++_citrun.data[1], (++_citrun.data[1], argc == 1)))
		return (++_citrun.data[2], 1);
	else
		return(++_citrun.data[4], (14));

	if ((++_citrun.data[6], ((++_citrun.data[6], argc = 2))))
		return (++_citrun.data[7], 5);
	else
		return(++_citrun.data[9], (0));
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
    1 Function definitions
    2 If statements
    4 Return statement values
    21 Total statements
    2 Binary operators
Modified source written successfully.
EOF

# Run the command.
$inst->run( args => '-c if.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'if.c');

# Sanitize paths from stdout.
my $check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 };
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
