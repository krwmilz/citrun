#
# This package writes and compiles a small C program with citrun.
#
package t::program;
use strict;
use warnings;
use File::Copy "cp";

sub new {
	my ($class, $tmp_dir) = @_;

	my $self = {};
	bless($self, $class);

	write_file("$tmp_dir/main.c", <<END);
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
END

	write_file("$tmp_dir/fib.c", <<END);
long long
fib(long long n)
{
	if (n == 0)
		return 0;
	else if (n == 1)
		return 1;

	return fib(n - 1) + fib(n - 2);
}
END

	write_file("$tmp_dir/print.c", <<END);
#include <stdio.h>

void
print_output(long long n)
{
	fprintf(stderr, "%lli", n);
	return;
}
END

	write_file("$tmp_dir/Makefile", <<END);
program: main.o fib.o print.o
	cc -o program main.o fib.o print.o
END

	system("src/citrun-wrap make -C $tmp_dir");
}

sub write_file {
	my ($file_name, $source) = @_;

	open my $fh, ">", $file_name or die "Can't write $file_name: $!";
	print $fh $source;
	close $fh;
}

1;
