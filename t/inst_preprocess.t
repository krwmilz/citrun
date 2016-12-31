#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 8;
unified_diff;	# for Test::Differences

my $preproc = 'int main(void) { return 0; }';

my $inst = Test::Cmd->new( prog => 'src/citrun_inst', workdir => '' );
$inst->write( 'prepro.c', $preproc );

# Test -E
my $check_good = <<EOF ;
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
Switching argv[0] ''
Preprocessor argument -E found
Running as citrun_inst, not calling exec()
EOF

$inst->run( args => '-E prepro.c', chdir => $inst->curdir );

# This file should not have been modified.
my $inst_out;
$inst->read(\$inst_out, 'prepro.c');

# Sanitize paths from stdout.
my $check_out = $inst->stdout;
$check_out =~ s/^.*Milliseconds spent.*\n//gm;
$check_out =~ s/'.*'/''/gm;
$check_out =~ s/\(.*\)/\(\)/gm;

eq_or_diff( $inst_out,	$preproc, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_good,	$check_out, 'is citrun_inst output identical';
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );

# Test -MM
$check_good = <<EOF ;
>> citrun_inst v0.0 ()
CITRUN_SHARE = ''
Switching argv[0] ''
Preprocessor argument -MM found
Running as citrun_inst, not calling exec()
EOF

$inst->run( args => '-MM prepro.c', chdir => $inst->curdir );

# This file should not have been modified.
my $inst_out;
$inst->read(\$inst_out, 'prepro.c');

# Sanitize paths from stdout.
my $check_out = $inst->stdout;
$check_out =~ s/^.*Milliseconds spent.*\n//gm;
$check_out =~ s/'.*'/''/gm;
$check_out =~ s/\(.*\)/\(\)/gm;

eq_or_diff( $inst_out,	$preproc, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_good,	$check_out, 'is citrun_inst output identical';
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
