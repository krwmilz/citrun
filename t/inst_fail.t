#
# Check that a program that won't compile natively is handled properly.
#
use strict;
use warnings;

use t::utils;
plan tests => 2;


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );

$inst->write( 'bad.c', <<EOF );
int
main(void)
{
	return 0;
EOF

$inst->run( args => '-c bad.c', workdir => $inst->curdir );

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
clang: error: error reading ''
Rewriting failed.
EOF

my $out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $out,	$out_good,	'is citrun_inst output identical', { context => 3} );
print $inst->stderr;
is( $? >> 8,		1,		'is citrun_inst exit code 1' );
