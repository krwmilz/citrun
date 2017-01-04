#
# Check that a program that won't compile natively is handled properly.
#
use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More tests => 2;
use t::utils;
unified_diff;


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
CITRUN_COMPILERS = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Rewriting failed.
EOF

my $out = t::utils::clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $out,	$out_good,	'is citrun_inst output identical' );
print $inst->stderr;
is( $? >> 8,		1,		'is citrun_inst exit code 1' );
