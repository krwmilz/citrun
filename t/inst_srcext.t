#
# Check that the advertised source file extensions work.
#
use Modern::Perl;
use t::utils;
plan tests => 15;


my @supported_exts = ("c", "cc", "cxx", "cpp");

my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );

my $out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Found source file ''
Command line is ''
Added clangtool argument ''
Instrumentation of '' finished:
    1 Lines of source code
    1 Function definitions
    1 Return statement values
    3 Total statements
Modified source written successfully.
EOF

for (@supported_exts) {
	$inst->write( "main.$_", 'int main(void) { return 0; }' );
	$inst->run( args => "-c main.$_", chdir => $inst->curdir );

	my $out = clean_citrun_log(scalar $inst->stdout);
	eq_or_diff( $out, $out_good,	".$_: is citrun_inst output identical", { context => 3} );
	is ( $inst->stderr,	'',	".$_: is citrun_inst stderr silent" );
	is( $? >> 8,		0,	".$_: is citrun_inst exit code 0" );
}

$out_good = <<EOF;
>> citrun_inst
Compilers path = ''
Command line is ''
No source files found on command line.
Running as citrun_inst, not calling exec()
EOF

$inst->write( "main.z", 'int main(void) { return 0; }' );
$inst->run( args => "-c main.z", chdir => $inst->curdir );

my $out = clean_citrun_log(scalar $inst->stdout);
eq_or_diff( $out, $out_good,	".z: is citrun_inst output identical", { context => 3 } );
is ( $inst->stderr,	'',	".z: is citrun_inst stderr silent" );
is( $? >> 8,		0,	".z: is citrun_inst exit code 1" );
