#
# Make sure that switch statement condition instrumentation works.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
use t::utils;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );
$inst->write( 'switch.c', <<EOF );
int main(void)
{
	int i;

	switch (i) {
	case 0:
		break;
	case 1:
		break;
	}

	return 0;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int main(void)
{++_citrun.data[0];++_citrun.data[1];
	int i;

	switch ((++_citrun.data[4], i)) {
	case 0:
		break;
	case 1:
		break;
	}

	return (++_citrun.data[11], 0);
}
EOF

my $check_good = <<EOF;
>> citrun_inst
CITRUN_SHARE = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    14 Lines of source code
    1 Function definitions
    1 Switch statements
    1 Return statement values
    14 Total statements
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c switch.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'switch.c');

# Sanitize paths from stdout.
my $check_out = t::utils::clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 } ;
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
