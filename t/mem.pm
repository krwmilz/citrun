package t::mem;

use strict;
use warnings;

use Inline 'C';
use POSIX;
use if $^O eq 'MSWin32', 't::mem_win32';
use if $^O ne 'MSWin32', 't::mem_unix';
use autodie;

sub new {
	my ($class, $procfile) = @_;

	my $self = {};
	bless($self, $class);

	get_mem( $self, $procfile );

	# These functions proved by C code at the end of this file.
	my $header_size = citrun_header_size();
	my $node_fixed_size = citrun_node_size();

	(	$self->{magic},
		$self->{major}, $self->{minor},
		$self->{pids}[0], $self->{pids}[1], $self->{pids}[2],
		$self->{units},
		$self->{loc},
		$self->{progname},
		$self->{cwd}
	) = unpack("Z4I7Z1024Z1024", $self->{mem});

	my %trans_units;
	my $node_start = get_aligned_size($header_size);

	while ($node_start < $self->{size}) {
		# Struct field ordering controlled by lib.h.
		my $data = substr($self->{mem}, $node_start, $node_fixed_size);
		my @struct_fields = unpack("IZ256Z256", $data);

		# Store a hash of information we just found.
		my $buf_size = $struct_fields[0];
		$trans_units{ $struct_fields[2] } = {
			size => $buf_size,
			comp_file_name => $struct_fields[1],
			exec_buf_pos => $node_start + $node_fixed_size
		};

		# Calculate where the end of this node is.
		my $node_end = $node_start + $node_fixed_size + ($buf_size * 8);
		$node_start = get_aligned_size($node_end);
	}
	$self->{trans_units} = \%trans_units;

	return $self;
}

sub get_aligned_size {
	my ($unaligned_size) = @_;

	my $page_mask = $t::mem::os_allocsize - 1;
	return ($unaligned_size + $page_mask) & ~$page_mask;
}

sub get_buffers {
	my ($self, $tu_key) = @_;

	my $tu = $self->{trans_units}->{$tu_key};
	my $data = substr($self->{mem}, $tu->{exec_buf_pos}, $tu->{size} * 8);
	my @execs = unpack("Q$tu->{size}", $data);

	return \@execs;
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
