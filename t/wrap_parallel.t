#
# Check that calling citrun_inst in parallel doesn't cause any obviously bad
# things to happen.
#
use strict;
use warnings;

use File::Which;
use t::utils;

plan skip_all => 'make not found' unless (which 'make');
plan tests => 15;


my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

$wrap->write( 'main1.c', 'int main(void) { return 0; }' );
$wrap->write( 'main2.c', 'int main(void) { return 0; }' );
$wrap->write( 'main3.c', 'int main(void) { return 0; }' );
$wrap->write( 'main4.c', 'int main(void) { return 0; }' );
$wrap->write( 'Makefile', <<'EOF' );
all: program1 program2 program3 program4

program1: main1.o
	cc -o program1 main1.o
program2: main2.o
	cc -o program2 main2.o
program3: main3.o
	cc -o program3 main3.o
program4: main4.o
	cc -o program4 main4.o
EOF

$wrap->run( args => 'make -j4', chdir => $wrap->curdir );
print $wrap->stdout;
is( $wrap->stderr,	'',	'is citrun_wrap make stderr silent' );
is( $? >> 8,		0,	'is citrun_wrap make exit code 0' );

my $check_good = <<EOF;
Summary:
         4 Source files used as input
         4 Application link commands
         4 Successful modified source compiles

Totals:
         4 Lines of source code
         4 Function definitions
         4 Return statement values
        12 Total statements
EOF

$wrap->run( prog => 'citrun_check', chdir => $wrap->curdir );
my $check_out = $wrap->stdout;
$check_out =~ s/^.*Milliseconds spent rewriting.*\n//gm;
eq_or_diff( $check_out, $check_good,	'is citrun_check stdout identical', { context => 3 } );

$ENV{CITRUN_PROCDIR} = $wrap->workdir;
for (1..4) {
	$wrap->run( prog => $wrap->workdir . "/program$_", chdir => $wrap->curdir );
	is( $wrap->stdout,	'',	"is instrumented program$_ stdout silent" );
	is( $wrap->stderr,	'',	"is instrumented program$_ stderr silent" );
	is( $? >> 8,		0,	"is instrumented program$_ exit code 0" );
}
