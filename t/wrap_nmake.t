use strict;
use warnings;
use t::utils;

plan skip_all => 'win32 only' if ($^O ne "MSWin32");
plan tests => 6;

my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->write( 'Makefile', <<EOF );
CFLAGS = /nologo

main.exe: main.obj
EOF

$wrap->run( args => 'nmake /nologo', chdir => $wrap->curdir );
print $wrap->stdout;
is( $wrap->stderr, '',	'is citrun_wrap nmake stderr silent' );
is( $? >> 8,	0,	'is citrun_wrap nmake exit code 0' );

my $log_good = <<EOF ;
>> citrun_inst
CITRUN_COMPILERS = ''
PATH=''
Found source file ''
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
>> citrun_inst
CITRUN_COMPILERS = ''
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
$citrun_log = clean_citrun_log( $citrun_log );

eq_or_diff( $citrun_log,	$log_good,	'is nmake citrun.log identical',
	{ context => 3 } );

$wrap->run( prog => $wrap->workdir . "/main", chdir => $wrap->curdir );
is( $wrap->stdout,	'',	'is instrumented program stdout silent' );
is( $wrap->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,		0,	'is main exit code 1' );
