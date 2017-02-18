#
# Check that instrumentation works when the -ansi flag is passed during
# compilation.
#
use Modern::Perl;
use t::utils;
plan tests => 3;


my $cc = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );
$cc->write( 'main.c', 'int main(void) { return 0; }' );

if ($^O eq 'MSWin32') {
	$cc->run( args => 'cl /nologo /Za main.c', chdir => $cc->curdir );
} else {
	$cc->run( args => 'cc -ansi -o main main.c', chdir => $cc->curdir );
}
#is( $cc->stdout,	'',		'is citrun_wrap cc stdout silent' );
is( $cc->stderr,	'',		'is citrun_wrap cc stderr silent' );
is( $? >> 8,		0,		'is citrun_wrap cc exit code 0' );

my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Link detected, adding '' to command line.
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
EOF

my $log_out;
$cc->read( \$log_out, 'citrun.log' );
eq_or_diff( clean_citrun_log($log_out),	$log_good, 'is citrun.log identical');
