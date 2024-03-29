#
# Check that a program that won't compile natively is handled properly.
#
use Modern::Perl;
use t::utils;
plan tests => 2;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );

$inst->write( 'bad.c', <<EOF );
int
main(void)
{
	return 0;
EOF

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    5 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
EOF

$inst->run( args => '-c bad.c', chdir => $inst->curdir );

my $out = clean_citrun_log(scalar $inst->stdout);
eq_or_diff( $out,	$out_good,	'is citrun_inst output identical', { context => 3} );

print $inst->stderr;
is( $? >> 8,		0,		'is citrun_inst exit code 0' );
