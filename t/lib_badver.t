#
# Check that linking object files of one citrun version with libcitrun of
# another errors.
#
use Modern::Perl;
use t::utils;		# os_compiler()
plan tests => 4;


my $compiler = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

$compiler->write( 'main.c', <<EOF );
#include <stddef.h>

struct citrun_node;
void citrun_node_add(unsigned int, unsigned int, struct citrun_node *);

int
main(int argc, char *argv[])
{
	citrun_node_add(0, 255, NULL);
}
EOF

$compiler->run( args => os_compiler() . 'main main.c', chdir => $compiler->curdir );
# is( $compiler->stdout,	'',	'is compiler stdout silent' );
is( $compiler->stderr,	'',	'is compiler stderr silent' );
is( $? >> 8,		0,	'is compiler exit code 0' );

my $err_good = 'libcitrun 0.0: incompatible version 0.255.
Try cleaning and rebuilding your project.
';

$ENV{CITRUN_PROCDIR} = $compiler->workdir;
my $abs_prog_path = File::Spec->catfile( $compiler->workdir, "main" );
$compiler->run( prog => $abs_prog_path, chdir => $compiler->curdir );
is( $compiler->stdout,	'',		'is incompatible node program stdout silent' );
is( $compiler->stderr,	$err_good,	'is incompatible node program stdout silent' );
