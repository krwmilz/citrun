#
# Check that the most basic of compile command lines works.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 3;
unified_diff;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );

if ($^O eq "MSWin32") {
	$wrap->run( args => 'cl /nologo main.c', chdir => $wrap->curdir );
} else {
	$wrap->run( args => 'cc main.c', chdir => $wrap->curdir );
}

my $log_good = <<EOF;
>> citrun_inst
CITRUN_SHARE = ''
PATH=''
Found source file ''
Link detected, adding '' to command line.
Modified command line is ''
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
EOF

my $citrun_log;
$wrap->read( \$citrun_log, 'citrun.log' );

$citrun_log =~ s/^.* citrun_inst.*\n/>> citrun_inst\n/gm;
$citrun_log =~ s/^.*Milliseconds spent.*\n//gm;
$citrun_log =~ s/'.*'/''/gm;
$citrun_log =~ s/^[0-9]+: //gm;

eq_or_diff( $citrun_log, $log_good, 'is citrun.log file identical', { context => 3 } );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap stderr empty' );
is( $? >> 8,		0,	'is citrun_wrap exit code 0' );