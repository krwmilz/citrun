#
# Test that binary operators in strange cases work. Includes enums and globals.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'src/citrun_inst', workdir => '' );
$inst->write( 'binop.c', <<EOF );
enum ASDF {
	ONE = (1 << 0),
	TWO = (1 << 1),
	THR = (1 << 2)
};

static int foo = 5 + 5;

static const struct {
	int i;
	unsigned char data[0 + 64 * 6];
} blah;

int main(void) {
	if (4 + 3)
		return 0;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
enum ASDF {
	ONE = (1 << 0),
	TWO = (1 << 1),
	THR = (1 << 2)
};

static int foo = 5 + 5;

static const struct {
	int i;
	unsigned char data[0 + 64 * 6];
} blah;

int main(void) {++_citrun.data[13];
	if ((++_citrun.data[14], (++_citrun.data[14], 4 + 3)))
		return (++_citrun.data[15], 0);
}
EOF

my $check_good = <<EOF;
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    18 Lines of source code
    1 Function definitions
    1 If statements
    1 Return statement values
    7 Total statements
    1 Binary operators
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c binop.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'binop.c');

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
