package t::shm;
use strict;
use warnings;
use POSIX;

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);

sub new {
	my ($class, $procfile) = @_;

	my $self = {};
	bless($self, $class);

	open(my $fh, "<:mmap", $procfile) or die $!;

	$self->{fh} = $fh;
	$self->{size} = (stat $procfile)[7];

	(	$self->{magic},
		$self->{major}, $self->{minor},
		$self->{pids}[0], $self->{pids}[1], $self->{pids}[2],
		$self->{progname},
		$self->{cwd}
	) = unpack("Z4I5Z1024Z1024", xread($fh, $pagesize));

	my @translation_units;
	while (tell $fh < $self->{size}) {
		my %tu;

		($tu{size}, $tu{comp_file_name}, $tu{abs_file_path}) =
			unpack("IZ1024Z1024", xread($fh, 4 + 2 * 1024 + 4 + 8));

		$tu{exec_buf_pos} = tell $fh;
		xread($fh, $tu{size} * 8);
		$self->next_page();

		push @translation_units, (\%tu);
	}
	$self->{translation_units} = \@translation_units;

	return $self;
}

# Skips to the next page boundary. If exactly on a page boundary then stay
# there.
sub next_page {
	my ($self) = @_;

	my $page_mask = $pagesize - 1;
	my $cur_pos = tell $self->{fh};

	seek $self->{fh}, ($cur_pos + $page_mask) & ~$page_mask, 0;
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
