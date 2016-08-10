package Test::Project;
use strict;

use Cwd;
use File::Temp qw( tempdir );
use Test;
use IPC::Open2;

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	# Make new temporary directory, clean it up at exit
	my $tmp_dir = tempdir( CLEANUP => 1 );

	# Use the tools in this source tree
	$ENV{PATH} = cwd . "/src:$ENV{PATH}";
	$ENV{CITRUN_SOCKET} = "test.socket";
	chdir $tmp_dir;

	write_file("one.c", <<EOF);
#include <err.h>
#include <stdlib.h>

long long fib(long long);
void print_output(long long);

int
main(int argc, char *argv[])
{
	long long n;

	if (argc != 2)
		errx(1, "argc != 2");

	n = atoi(argv[1]);

	print_output(fib(n));
	return 0;
}
EOF

	write_file("two.c", <<EOF);
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

	write_file("three.c", <<EOF);
#include <stdio.h>

void
print_output(long long n)
{
	fprintf(stderr, "%lli", n);
	return;
}
EOF

	write_file("Jamfile", <<EOF);
Main program : one.c two.c three.c ;
EOF

	my $ret = system( "jam" );
	die "jam failed: $ret\n" if ($ret);

	return $self;
}

sub write_file {
	my ($name, $content) = @_;
	open( my $src_fh, ">", $name );
	print $src_fh $content;
	close( $src_fh );
}

sub run {
	my ($self, @args) = @_;
	$self->{pid} = open2(\*CHLD_OUT, undef, "program", @args);
}

sub kill {
	my ($self) = @_;
	kill 'TERM', $self->{pid};
}

sub wait {
	my ($self) = @_;

	waitpid( $self->{pid}, 0 );
	my $real_ret = $? >> 8;

	my $stderr;
	while (my $line = <CHLD_OUT>) {
		$stderr .= $line;
	}

	return ($real_ret, $stderr);
}

sub DESTROY {
	my ($self) = @_;

	$self->kill() if ($self->{pid});
}

1;
