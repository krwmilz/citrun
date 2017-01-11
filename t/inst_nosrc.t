#
# Check that giving citrun_inst a non existent file is handled.
#
use strict;
use warnings;
use t::utils;
plan tests => 2;


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );
$inst->run( args => '-c doesnt_exist.c', workdir => $inst->curdir );

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Modified command line is ''
Added clangtool argument ''
Rewriting failed.
EOF

my $out = clean_citrun_log(scalar $inst->stdout);

eq_or_diff( $out,	$out_good,	'is citrun_inst output identical' );
print $inst->stderr;
is( $? >> 8,		1,		'is citrun_inst exit code 1' );
