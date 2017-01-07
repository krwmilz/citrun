use strict;
use warnings;
use File::Util;
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

sub get_one_shmfile {
	my ($dir) = @_;
	opendir( DIR, $dir ) or die $!;

	my @files;
	for (readdir(DIR)) {
		next if ($_ eq ".");
		next if ($_ eq "..");
		push @files, ($_);
	}

	closedir(DIR);
	die "not exactly one procfile found" if (scalar @files != 1);

	return File::Spec->catfile( $dir, $files[0] );
}

sub setup_projdir {

	my $wrap = Test::Cmd->new( prog => 'citrun_wrap', workdir => '' );

	$ENV{CITRUN_PROCDIR} =  File::Spec->catdir( $wrap->workdir, "procdir" );
	$ENV{CITRUN_PROCDIR} .= File::Util->SL;

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

package t::shm;
use Inline 'C';
use POSIX;

sub new {
	my ($class, $procfile) = @_;

	my $self = {};
	bless($self, $class);

	my $fh;
	if ($^O eq "MSWin32") {
		open($fh, "<", $procfile) or die $!;
	} else {
		open($fh, "<:mmap", $procfile) or die $!;
	}
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

	my $node_fixed_size = citrun_node_size();
	my %trans_units;

	while (not eof $fh) {
		my @struct_fields = unpack("IZ1024Z1024", xread($fh, $node_fixed_size));
		my $buf_pos = tell $fh;
		my $buf_size = $struct_fields[0];

		my %tu;
		$trans_units{ $struct_fields[2] } = {
			size => $buf_size,
			comp_file_name => $struct_fields[1],
			exec_buf_pos => $buf_pos
		};

		my $node_end = $buf_pos + ($buf_size * 8);
		my $node_end_aligned = get_aligned_size($node_end);

		seek $self->{fh}, $node_end_aligned, 0;
		$self->{size} = $node_end_aligned;
	}
	$self->{trans_units} = \%trans_units;

	return $self;
}

sub get_aligned_size {
	my ($unaligned_size) = @_;

	my $page_mask;
	if ($^O eq "MSWin32") {
		$page_mask = 64 * 1024 - 1;
	} else {
		$page_mask = POSIX::sysconf(POSIX::_SC_PAGESIZE) - 1;
	}

	return ($unaligned_size + $page_mask) & ~$page_mask;
}

sub get_buffers {
	my ($self, $tu_key) = @_;

	my $tu = $self->{trans_units}->{$tu_key};
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
#include "../lib.h"

size_t citrun_header_size() {
	return sizeof(struct citrun_header);
}

size_t citrun_node_size() {
	return sizeof(struct citrun_node);
}
