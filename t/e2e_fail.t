#
# Check that a program that won't compile natively is handled properly.
#
use Modern::Perl;
use t::utils;
plan tests => 3;


my $inst = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

$inst->write( 'bad.c', <<EOF );
int
main(void)
{
	return 0;
EOF

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    5 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Forked compiler ''
Rewritten source compile failed
Restored ''
EOF

$inst->run( args => 'cc -c bad.c', chdir => $inst->curdir );
is( $inst->stdout,	'',		'is citrun_wrap stdout silent' );
print $inst->stderr;
is( $? >> 8,		1,		'is citrun_wrap exit code 1' );

my $out;
$inst->read( \$out, 'citrun.log' );
$out = clean_citrun_log($out);

eq_or_diff( $out,	$out_good,	'is citrun.log file identical', { context => 3} );
