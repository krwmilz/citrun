package tlib::shm;
use strict;
use warnings;
use POSIX;

# Triggers runtime to use alternate shm path.
$ENV{CITRUN_TOOLS} = 1;

my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);

sub new {
	my ($class) = @_;

	my $self = {};
	bless($self, $class);

	open(my $fh, "<:mmap", "procfile.shm") or die $!;

	$self->{fh} = $fh;
	$self->{size} = (stat "procfile.shm")[7];

	( $self->{magic}, $self->{major}, $self->{minor},
		$self->{pids}[0], $self->{pids}[1], $self->{pids}[2],
		$self->{progname}, $self->{cwd}
	) = unpack("Z6CCLLLZ" . PATH_MAX . "Z" . PATH_MAX, xread($fh, $pagesize));

	my @translation_units;
	while (tell $fh < $self->{size}) {
		my %tu;

		($tu{size}, $tu{comp_file_name}, $tu{abs_file_path}) =
			unpack("LZ" . PATH_MAX . "Z" . PATH_MAX, xread($fh, 4 + 2 * 1024 + 4 + 8));

		$tu{exec_buf_pos} = tell $fh;
		xread($fh, $tu{size} * 8);
		$self->next_page();

		push @translation_units, (\%tu);
	}
	$self->{translation_units} = \@translation_units;

	return $self;
}

sub next_page {
	my ($self) = @_;

	my $cur_pos = tell $self->{fh};
	xread($self->{fh}, $pagesize - ($cur_pos % $pagesize));
}

sub execs_for {
	my ($self, $tu_num) = @_;

	my $tu = $self->{translation_units}->[$tu_num];
	seek $self->{fh}, $tu->{exec_buf_pos}, 0;
	my @execs = unpack("Q$tu->{size}", xread($self->{fh}, $tu->{size} * 8));

	return \@execs;
}

sub print_tus {
	my ($self) = @_;

	my $transl_units = $self->{translation_units};
	for (@$transl_units) {
		my %tu = %$_;

		print "$tu{comp_file_name} $tu{size}\n";
	}
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

sub DESTROY {
	unlink "procfile.shm";
}

1;
