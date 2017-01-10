use strict;
use warnings;

use if $^O eq "MSWin32", 'File::DosGlob' => 'glob';
use Test::Cmd;
use Test::Differences;
use Test::More;

use autodie;
unified_diff;		# For Test::Differences diffs


sub os_compiler {
	if ($^O eq 'MSWin32') {
		return 'cl /nologo /Fe';
	}
	return 'cc -o ';
}

sub clean_citrun_log {
	my ($log) = @_;

	$log =~ s/>> citrun_inst.*\n/>> citrun_inst\n/gm;
	$log =~ s/^.*Milliseconds spent.*\n//gm;
	$log =~ s/'.*'/''/gm;
	$log =~ s/^[0-9]+: //gm;

	return $log;
}

sub get_one_shmfile {
	my ($dir) = @_;

	my @files = glob File::Spec->catfile( $dir, "program_*");
	die "not exactly one procfile found" if (scalar @files != 1);

	return $files[0];
}

sub setup_projdir {

	my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );
	$ENV{CITRUN_PROCDIR} =  $wrap->workdir;

	$wrap->write( 'main.c', <<EOF);
#include <stdio.h>
#include <stdlib.h>

long long fib(long long);
void print_output(long long);

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2) {
		fprintf(stderr, "argc != 2");
		exit(1);
	}

	n = atoi(argv[1]);

	print_output(fib(n));
	return 0;
}
EOF

	$wrap->write( 'print.c', <<EOF );
#include <stdio.h>

void
print_output(long long n)
{
	printf("%lli", n);
	return;
}
EOF

	$wrap->write( 'fib.c', <<EOF );
long long
fib(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fib(n - 1) + fib(n - 2);
}
EOF

	$wrap->write( 'Jamfile', <<EOF );
Main program : main.c fib.c print.c ;
EOF

	$wrap->run( args => 'jam', chdir => $wrap->curdir );

	is( $wrap->stderr,	'',	'is citrun_wrap jam stderr empty' );
	is( $? >> 8,		0,	'is citrun_wrap jam exit code 0' );

	return $wrap;
}
