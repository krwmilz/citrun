#
# Test that wrapping the 'cmake' build system produces instrumented binaries.
#
use File::Which;
use Modern::Perl;
use t::utils;

plan skip_all => 'cmake not found' unless (which 'cmake');
plan tests => 8;


my $wrap = Test::Cmd->new( prog => 'bin/citrun_wrap', workdir => '' );

$wrap->write( 'CMakeLists.txt', <<'EOF' );
cmake_minimum_required (VERSION 2.6)
project (program)
add_executable(program main.c)
EOF

# Log file after make is ran on Makefile generated by CMake.
my $log_good = <<EOF;
>> citrun_inst
Compilers path = ''
PATH = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    6 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
Forked compiler ''
Rewritten source compile successful
Restored ''
>> citrun_inst
Compilers path = ''
PATH = ''
Link detected, adding '' to command line.
Command line is ''
No source files found on command line.
EOF

$wrap->write( 'main.c', <<'EOF' );
int
main(void)
{
	return 0;
}
EOF

# Run CMake.
$wrap->run( args => 'cmake .', chdir => $wrap->curdir );

print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap cmake stderr empty');
is( $? >> 8,		0,	'is citrun_wrap cmake exit code 0');

# Now run whatever platform specific-ish files CMake decided to give us.
if ($^O eq "MSWin32") {
	# MSBuild currently does not work.
	$wrap->run( args => 'devenv /useenv program.sln /Build', chdir => $wrap->curdir );
} else {
	$wrap->run( args => 'make', chdir => $wrap->curdir );
}

my $log_out;
$wrap->read( \$log_out, 'citrun.log' );
$log_out = clean_citrun_log($log_out);

eq_or_diff( $log_out, $log_good,	'is citrun.log identical', { context => 3 } );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap make stderr empty');
is( $? >> 8,		0,	'is citrun_wrap make exit code 0');

$ENV{CITRUN_PROCDIR} = $wrap->workdir;

# Check the instrumented program runs.
$wrap->run( prog => $wrap->workdir . "/program", chdir => $wrap->curdir );

is( $wrap->stdout,	'',	'is instrumented program stdout empty');
is( $wrap->stderr,	'',	'is instrumented program stderr empty');
is( $? >> 8,		0,	'is instrumented program exit code 0');

#ok "is runtime shared memory file created" test -f procdir/program_*
