#
# The milliseconds spent processing line is always regex'ed out in other tests.
# Do the opposite here and make sure it's there.
#
use strict;
use warnings;

use t::utils;
plan tests => 3;


my $inst = Test::Cmd->new( prog => 'citrun_inst', workdir => '' );

$inst->write( 'main.c', <<EOF );
int main(void)
{
	return 0;
}
EOF

$inst->run( args => '-c main.c', chdir => $inst->curdir );

like( $inst->stdout,	qr/Milliseconds spent rewriting/, 'is milliseconds in citrun.log' );
is( $inst->stderr,	'',	'is citrun_inst stderr silent' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
