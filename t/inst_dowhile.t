#
# Make sure that do while loop condition instrumentation works.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'src/citrun_inst', workdir => '' );
$inst->write( 'dowhile.c', <<EOF );
int main(int argc, char *argv[]) {
	do {
		argc++;
	} while (argc != 10);
	return 0;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int main(int argc, char *argv[]) {++_citrun.data[0];
	do {
		argc++;
	} while ((++_citrun.data[3], (++_citrun.data[3], argc != 10)));
	return (++_citrun.data[4], 0);
}
EOF

my $check_good = <<EOF;
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
Switching argv[0] ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    7 Lines of source code
    1 Function definitions
    1 Do while loops
    1 Return statement values
    11 Total statements
    1 Binary operators
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c dowhile.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'dowhile.c');

# Sanitize paths from stdout.
my $check_out = $inst->stdout;
$check_out =~ s/^.*Milliseconds spent.*\n//gm;
$check_out =~ s/'.*'/''/gm;
$check_out =~ s/\(.*\)/\(\)/gm;

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_good,	$check_out, 'is citrun_inst output identical';
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );