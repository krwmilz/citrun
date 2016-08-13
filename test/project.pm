package test::project;
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
#include <signal.h>
#include <stdlib.h>

long long fib(long long);
void print_output(long long);

void
usr1_sig(int signal)
{
	exit(0);
}

int
main(int argc, char *argv[])
{
	struct sigaction sa;
	long long n;

	if (argc != 2)
		errx(1, "argc != 2");

	sa.sa_handler = &usr1_sig;
	sa.sa_flags = SA_RESTART;
	sigfillset(&sa.sa_mask);
	if (sigaction(SIGUSR1, &sa, NULL) == -1)
		err(1, "sigaction");

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
	kill 'USR1', $self->{pid};
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
