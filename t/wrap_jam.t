#
# Test that wrapping the 'jam' build system produces instrumented binaries.
#
use File::Which;
use Modern::Perl;
use t::utils;

plan skip_all => 'jam not found' unless (which 'jam');
plan tests => 6;


my $wrap = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->write( 'Jamfile', <<EOF );
Main program : main.c ;
EOF

$wrap->run( args => 'jam', chdir => $wrap->curdir );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap jam stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap jam exit code 0' );

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

if ($^O eq 'MSWin32') {
	# Windows gets an extra message because exec() is emulated by fork().
	$log_good .= <<EOF ;
Forked compiler ''
EOF
}


$wrap->read( \$citrun_log, 'citrun.log' );
$citrun_log = clean_citrun_log( $citrun_log );

eq_or_diff( $citrun_log, $log_good,	'is citrun_wrap log file identical', { context => 3 } );

$ENV{CITRUN_PROCDIR} = $wrap->workdir;
$wrap->run( prog => $wrap->workdir . '/program', chdir => $wrap->curdir );
is( $wrap->stdout,	'',	'is instrumented program stdout silent' );
is( $wrap->stderr,	'',	'is instrumented program stderr silent' );
is( $? >> 8,		0,	'is instrumented program exit code 0' );
