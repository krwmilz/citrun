package test::shm;
use strict;
use warnings;
use Cwd;
use POSIX;

$ENV{CITRUN_TOOLS} = cwd . '/src';

sub new {
	my ($class) = @_;

	my $self = {};
	bless($self, $class);

	open(my $fh, "<:mmap", "procfile.shm") or die $!;
	$self->{fh} = $fh;
	$self->{size} = (stat "procfile.shm")[7];

	($self->{major}, $self->{minor}) = unpack("C2", xread($fh, 2));
	@{ $self->{pids} } = unpack("L3", xread($fh, 12));

	($self->{prg_sz}) = unpack("S", xread($fh, 2));
	($self->{progname}) = xread($fh, $self->{prg_sz});
	($self->{cwd_sz}) = unpack("S", xread($fh, 2));
	($self->{cwd}) = xread($fh, $self->{cwd_sz});
	$self->next_page();

	my @translation_units;
	while (tell $fh < $self->{size}) {
		my %tu;
		($tu{size}) = unpack("L", xread($fh, 4));

		($tu{cmp_sz}) = unpack("S", xread($fh, 2));
		$tu{comp_file_name} = xread($fh, $tu{cmp_sz});
		($tu{abs_sz}) = unpack("S", xread($fh, 2));
		$tu{abs_file_path} = xread($fh, $tu{abs_sz});

		$tu{exec_buf_pos} = tell $fh;
		xread($fh, $tu{size} * 8);
		$self->next_page();

		push @translation_units, (%tu);
	}
	$self->{translation_units} = \@translation_units;

	return $self;
}

sub next_page {
	my ($self) = @_;

	my $pagesize = POSIX::sysconf(POSIX::_SC_PAGESIZE);
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

#
# Read an exact amount of bytes.
#
sub xread {
	my ($fh, $bytes_total) = @_;

	my $data;
	my $bytes_read = 0;
	while ($bytes_total > 0) {
		my $read = read($fh, $data, $bytes_total, $bytes_read);

		die "error: read failed: $!" if (!defined $read);
		die "disconnected!\n" if ($read == 0);

		$bytes_total -= $read;
		$bytes_read += $read;
	}

	return $data;
}

1;
