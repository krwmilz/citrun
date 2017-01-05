use strict;
use warnings;
use Test::Cmd;
use Test::Differences;
use Test::More;
unified_diff;		# For Test::Differences diffs


sub clean_citrun_log {
	my ($log) = @_;

	$log =~ s/>> citrun_inst.*\n/>> citrun_inst\n/gm;
	$log =~ s/^.*Milliseconds spent.*\n//gm;
	$log =~ s/'.*'/''/gm;
	$log =~ s/^[0-9]+: //gm;

	return $log;
}

sub make_testcmd {

	my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );
	#$ENV{CITRUN_PROCDIR} = $wrap->workdir . "\\procdir\\";

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
	fprintf(stderr, "%lli", n);
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

package t::shm;
use Inline 'C';
use POSIX;

sub new {
	my ($class, $procfile) = @_;

	my $self = {};
	bless($self, $class);

	open(my $fh, "<:mmap", $procfile) or die $!;
	$self->{fh} = $fh;

	my $header_size = citrun_header_size();
	my $aligned_size = get_aligned_size($header_size);

	(	$self->{magic},
		$self->{major}, $self->{minor},
		$self->{pids}[0], $self->{pids}[1], $self->{pids}[2],
		$self->{units},
		$self->{loc},
		$self->{done},
		$self->{progname},
		$self->{cwd}
	) = unpack("Z4I8Z1024Z1024", xread($fh, $aligned_size));

	my @translation_units;
	while (tell $fh < $self->stat_procfile()) {
		my %tu;

		my $node_fixed_size = citrun_node_size();
		(
			$tu{size},
			$tu{comp_file_name},
			$tu{abs_file_path}
		) = unpack("IZ1024Z1024", xread($fh, $node_fixed_size));

		$tu{exec_buf_pos} = tell $fh;

		my $node_end = $tu{exec_buf_pos} + ($tu{size} * 8);
		my $node_end_aligned = get_aligned_size($node_end);

		seek $self->{fh}, $node_end_aligned, 0;

		push @translation_units, (\%tu);
	}
	$self->{translation_units} = \@translation_units;

	return $self;
}

sub stat_procfile {
	my ($self) = @_;

	$self->{size} = (stat $self->{fh})[7];
	return $self->{size};
}

sub get_aligned_size {
	my ($unaligned_size) = @_;

	my $page_size = POSIX::sysconf(POSIX::_SC_PAGESIZE);
	my $page_mask = $page_size - 1;

	return ($unaligned_size + $page_mask) & ~$page_mask;
}

sub execs_for {
	my ($self, $tu_num) = @_;

	my $tu = $self->{translation_units}->[$tu_num];
	seek $self->{fh}, $tu->{exec_buf_pos}, 0;
	my @execs = unpack("Q$tu->{size}", xread($self->{fh}, $tu->{size} * 8));

	return \@execs;
}

#
# Read an exact amount of bytes.
#
sub xread {
	my ($fh, $bytes_total) = @_;

	my $data;
	my $bytes_read = 0;
	while ($bytes_total > 0) {
		my $read = read($fh, $data, $bytes_total, $bytes_read);

		die "read failed: $!" if (!defined $read);
		die "end of file\n" if ($read == 0);

		$bytes_total -= $read;
		$bytes_read += $read;
	}

	return $data;
}

1;
__DATA__
__C__
#include "../src/lib.h"

size_t citrun_header_size() {
	return sizeof(struct citrun_header);
}

size_t citrun_node_size() {
	return sizeof(struct citrun_node);
}
