#
# Test for some tricky macro situations. In particular macro expansions at the
# end of binary operators.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );
$inst->write( 'macro.c', <<EOF );
#define MAYBE 1023;

int main(int argc, char *argv[]) {
	int abd = 1023 + MAYBE;
	return 0;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
#define MAYBE 1023;

int main(int argc, char *argv[]) {++_citrun.data[2];
	int abd = 1023 + MAYBE;
	return (++_citrun.data[4], 0);
}
EOF

my $check_good = <<EOF;
>> citrun_inst
CITRUN_SHARE = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    7 Lines of source code
    1 Function definitions
    1 Return statement values
    7 Total statements
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c macro.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'macro.c');

# Sanitize paths from stdout.
my $check_out = $inst->stdout;
$check_out =~ s/^.* citrun_inst.*\n/>> citrun_inst\n/gm;
$check_out =~ s/^.*Milliseconds spent.*\n//gm;
$check_out =~ s/'.*'/''/gm;
$check_out =~ s/^[0-9]+: //gm;

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 };
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
