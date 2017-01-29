#
# Make sure preprocessor flags -E, -MM cause no instrumentation to be done.
#
use strict;
use warnings;

use t::utils;
plan tests => 8;


my $preproc = 'int main(void) { return 0; }';

my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );
$inst->write( 'prepro.c', $preproc );

# Test -E
my $check_good = <<EOF ;
>> citrun_inst
Compilers path = ''
Preprocessor argument -E found
Running as citrun_inst, not calling exec()
EOF

$inst->run( args => '-E prepro.c', chdir => $inst->curdir );

# This file should not have been modified.
my $inst_out;
$inst->read(\$inst_out, 'prepro.c');

# Sanitize paths from stdout.
my $check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$preproc, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical';
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );

# Test -MM
$check_good = <<EOF ;
>> citrun_inst
Compilers path = ''
Preprocessor argument -MM found
Running as citrun_inst, not calling exec()
EOF

$inst->run( args => '-MM prepro.c', chdir => $inst->curdir );

# This file should not have been modified.
$inst->read(\$inst_out, 'prepro.c');

# Sanitize paths from stdout.
$check_out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $inst_out,	$preproc, 'is instrumented file identical', { context => 3 } );
eq_or_diff $check_out,	$check_good, 'is citrun_inst output identical', { context => 3 };
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
