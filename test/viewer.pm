package test::viewer;

use strict;
use IO::Socket::UNIX;
use Test::More;

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	$self->{viewer_socket_name} = $ENV{CITRUN_SOCKET};
	my $viewer_socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM(),
		Local => $self->{viewer_socket_name},
		Listen => 1
	);
	die "socket error: $!\n" unless ($viewer_socket);

	$self->{viewer_socket} = $viewer_socket;
	return $self;
}

sub accept {
	my ($self) = @_;

	my $listen_sock = $self->{viewer_socket};
	my $sock = $listen_sock->accept();
	$self->{client_socket} = $sock;

	# Protocol defined in src/runtime.c function send_static().
	#
	($self->{maj}, $self->{min}) = read_unpack($sock, 2, "C2");
	($self->{ntus}) = read_unpack($sock, 4, "L");
	@{ $self->{pids} } =	read_unpack($sock, 12, "L3");
	$self->{progname} =	read_all($sock, read_unpack($sock, 2, "S"));
	$self->{cwd} =		read_all($sock, read_unpack($sock, 2, "S"));

	my @tus;
	for (1..$self->{ntus}) {
		my $comp_file_name = read_all($sock, read_unpack($sock, 2, "S"));
		my $abs_file_name = read_all($sock, read_unpack($sock, 2, "S"));
		my ($num_lines) = read_unpack($sock, 4, "L");

		# Keep this in order so it's easy to fetch dynamic data.
		push @tus, [ $abs_file_name, $num_lines ];
	}
	$self->{tus} = \@tus;
}

sub get_dynamic_data {
	my ($self) = @_;
	my $sock = $self->{client_socket};

	my %data;
	for my $tu (@{ $self->{tus} }) {
		my ($file_name, $nlines) = @{ $tu };

		# Protocol defined in src/runtime.c function send_dynamic().
		#
		if (read_unpack($sock, 1, "C") == 0) {
			$data{$file_name} = [ (0) x $nlines ];
			next;
		}
		$data{$file_name} = [ read_unpack($sock, 4 * $nlines, "L$nlines") ];
	}

	$sock->syswrite("\x01", 1);
	return \%data;
}

sub cmp_static_data {
	my ($self, $known_good) = @_;
	is( $self->{ntus}, scalar @$known_good, "translation unit count" );

	# Sort these alphabetically by file name (field 0).
	my @sorted_tus = sort { $a->[0] cmp $b->[0] } @{ $self->{tus} };

	for my $x (@$known_good) {
		my $y = shift @sorted_tus;

		like( $y->[0],	qr/.*$x->[0]/,	"$x->[0]: filename check" );
		is ( $y->[1],	$x->[1],	"$x->[0]: total lines check" );
	}
}

sub cmp_dynamic_data {
	my ($self) = @_;

	my $data = $self->get_dynamic_data();

	# Check that at least a single execution has taken place.
	my $good = 0;
	for my $key (sort keys %$data) {
		my $data_tmp = $data->{$key};

		for (@$data_tmp) {
			$good++ if ($_ > 0);
		}
	}
	cmp_ok( $good, ">", 0, "a single application execution took place" );

	return $data;
}

sub read_unpack {
	my ($sock, $bytes_total, $unpack_fmt) = @_;
	return unpack($unpack_fmt, read_all($sock, $bytes_total));
}

sub read_all {
	my ($sock, $bytes_total) = @_;

	my $data;
	my $bytes_read = 0;
	while ($bytes_total > 0) {
		my $read = $sock->sysread($data, $bytes_total, $bytes_read);

		die "error: read failed: $!" if (!defined $read);
		die "disconnected!\n" if ($read == 0);

		$bytes_total -= $read;
		$bytes_read += $read;
	}

	return $data;
}

sub close {
	my ($self) = @_;
	close ($self->{client_socket});
}

sub DESTROY {
	my ($self) = @_;

	close($self->{viewer_socket});
	unlink $self->{viewer_socket_name};
}

1;
