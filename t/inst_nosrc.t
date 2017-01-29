#
# Check that giving citrun_inst a non existent file is handled.
#
use strict;
use warnings;

use t::utils;
plan tests => 2;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
EOF

$inst->run( args => '-c doesnt_exist.c', chdir => $inst->curdir );

my $out = clean_citrun_log(scalar $inst->stdout);
eq_or_diff( $out,	$out_good,	'is citrun_inst output identical' );

print $inst->stderr;
is( $? >> 8,		0,		'is citrun_inst exit code 0' );
