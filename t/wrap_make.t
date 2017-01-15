#
# Test that wrapping the 'make' build system produces instrumented binaries.
#
use strict;
use warnings;

use File::Which;
use t::utils;

plan skip_all => 'make not found' unless (which 'make');
plan tests => 6;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->write( 'Makefile', <<'EOF' );
program: main.o
	cc -o program main.o
EOF

$wrap->run( args => 'make', chdir => $wrap->curdir );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap make stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap make exit code 0' );

my $citrun_log;
my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    1 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Rewriting successful.
Forked compiler ''
Rewritten source compile successful
Restored ''
>> citrun_inst
Compilers path = ''
PATH = ''
Link detected, adding '' to command line.
Command line is ''
No source files found on command line.
EOF

$wrap->read( \$citrun_log, 'citrun.log' );
$citrun_log = clean_citrun_log( $citrun_log );

eq_or_diff( $citrun_log, $log_good,	'is citrun_wrap log file identical', { context => 3 } );

$ENV{CITRUN_PROCDIR} = $wrap->workdir;
$wrap->run( prog => $wrap->workdir . '/program', chdir => $wrap->curdir );
is( $wrap->stdout,	'',	'is instrumented program stdout silent' );
is( $wrap->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,		0,	'is instrumented program exit code 0' );
