#
# Make sure that while loop condition instrumentation works.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 4;
use t::utils;
unified_diff;	# for Test::Differences


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );
$inst->write( 'while.c', <<EOF );
int main(int argc, char *argv[]) {
	while (argc < 17)
		argc++;

	while ((argc && argv));
	return 0;
}
EOF

# Known good output.
my $inst_good = <<EOF ;
int main(int argc, char *argv[]) {++_citrun.data[0];
	while ((++_citrun.data[1], (++_citrun.data[1], argc < 17)))
		argc++;

	while ((++_citrun.data[4], ((++_citrun.data[4], argc && argv))));
	return (++_citrun.data[5], 0);
}
EOF

my $check_good = <<EOF;
>> citrun_inst
CITRUN_SHARE = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    8 Lines of source code
    1 Function definitions
    2 While loops
    1 Return statement values
    18 Total statements
    2 Binary operators
Modified source written successfully.
Rewriting successful.
EOF

# Run the command.
$inst->run( args => '-c while.c', chdir => $inst->curdir );

# This file should have been rewritten in place.
my $inst_out;
$inst->read(\$inst_out, 'while.c');

# Sanitize paths from stdout.
my $check_out = t::utils::clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$inst_good, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 } ;
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
