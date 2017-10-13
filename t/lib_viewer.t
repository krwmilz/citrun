#
# Check that the runtime starts the viewer if no 'citrun_gl.lock' file exists.
#
# Cases:
# 1) not having `citrun_gl` on the PATH and citrun_gl.lock missing is ok
# 2) no lock file and `citrun_gl` on the PATH is ok
# 3) no viewer is executed when the lock file is present
#
use Modern::Perl;
use t::utils;		# os_compiler()

plan tests => 11;


my $wrap = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

# Write and compile bare minimum source file.
$wrap->write( 'main.c', 'int main(void) { return 0; }' );
$wrap->run( args => os_compiler() . 'main main.c', chdir => $wrap->curdir );

# Don't check stdout.
is(	$wrap->stderr,	'',	'is wrapped compile stderr silent' );
is(	$? >> 8,	0,	'is wrapped compile exit code 0' );

# Case 1.
my $inst_prog = Test::Cmd->new( prog => $wrap->workdir . "/main", workdir => '' );

$ENV{CITRUN_PROCDIR} = $inst_prog->workdir;
my $err_good = 'main: exec citrun_gl: No such file or directory';

$inst_prog->run( chdir => $inst_prog->curdir );
is(	$inst_prog->stdout,	'',		'is case 1 stdout silent' );
like(	$inst_prog->stderr,	qr/$err_good/,	'is case 1 stderr an error' );
is(	$? >> 8,		0,		'is case 1 exit code 0' );

# Case 2.
$inst_prog->write( 'citrun_gl', <<EOF );
#!/bin/sh
echo ran citrun_gl
EOF
chmod(0775, $inst_prog->workdir . '/citrun_gl') or die $!;

$inst_prog->run( chdir => $wrap->curdir );
like(	$inst_prog->stdout,	qr/ran citrun_gl/, 'is case 2 viewer started' );
is(	$inst_prog->stderr,	'',	'is case 2 stderr empty' );
is(	$? >> 8,		0,	'is case 2 exit code zero' );

# Case 3.
$inst_prog->write( $ENV{CITRUN_PROCDIR} . '/citrun_gl.lock', '' );
$inst_prog->run( chdir => $wrap->curdir );

is(	$inst_prog->stdout,	'',	'is case 3 stdout silent' );
is(	$inst_prog->stderr,	'',	'is case 3 stderr silent' );
is(	$? >> 8,		0,	'is case 3 exit code zero' );
