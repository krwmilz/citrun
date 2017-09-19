#
# Verify behaviour of citrun_report script. There's a few cases here.
#
use Modern::Perl;
use Test::Cmd;
use Test::More;

plan skip_all => 'citrun_check missing on win32' if ($^O eq "MSWin32");
plan tests => 12;


my $check = Test::Cmd->new( prog => 'bin/citrun_check', workdir => '' );

#
# Test when a nonexistent file argument is given.
#
my $error_good = "awk: can't open file _nonexistent_";
$check->run( args => '_nonexistent_', chdir => $check->curdir );

is( $check->stdout,	'',		'is nonexistent file stdout silent' );
like( $check->stderr,	qr/$error_good/, 'is nonexistent file stderr identical' );
is( $? >> 8,		2,		'is nonexistent file exit code nonzero' );

#
# Verify output when an empty file is processed.
#
my $output_good = "No signs of rewrite activity.";
$check->write( 'empty_file.log', '' );
$check->run( args => 'empty_file.log', chdir => $check->curdir );

like( $check->stdout,	qr/$output_good/, 'is empty file stdout expected' );
is( $check->stderr,	'',		'is empty file stderr silent' );
is( $? >> 8,		1,		'is empty file exit code nonzero' );

#
# Test when an existent file only has a header line.
#
$output_good = 'Summary:
         1 Rewrite tool runs';
$check->write( 'header_only.log', '>> citrun_inst');
$check->run( args => 'header_only.log', chdir => $check->curdir );

like( $check->stdout,	qr/$output_good/, 'is header only stdout expected' );
is( $check->stderr,	'',		'is header only stderr silent' );
is( $? >> 8,		0,		'is header only exit code zero' );

#
# Test a log file path with spaces.
#
$output_good = "No signs of rewrite activity.";

mkdir File::Spec->catdir( $check->workdir, 'dir a' );
$check->write( [ 'dir a', 'citrun.log' ], '' );

$check->run( args => 'dir\ a/citrun.log', chdir => $check->curdir );
like( $check->stdout,	qr/$output_good/, 'is path with spaces stdout identical' );
is( $check->stderr,	'',		'is path with spaces stderr silent' );
is( $? >> 8,		1,		'is path with spaces exit code nonzero' );
