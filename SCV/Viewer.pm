package SCV::Viewer;
use strict;

use IO::Socket::UNIX;
use Test;

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	my $viewer_socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM(),
		Local => "viewer_test.socket",
		Listen => 1,
	);
	die "socket error: $!\n" unless ($viewer_socket);

	$self->{viewer_socket} = $viewer_socket;
	return $self;
}

sub accept {
	my ($self) = @_;

	my $socket = $self->{viewer_socket};
	$self->{client_socket} = $socket->accept();
}

sub get_metadata {
	my ($self) = @_;
	my $client = $self->{client_socket};

	# First thing sent is total number of translation units
	my $buf = read_all($client, 8);
	my $num_tus = unpack("Q", $buf);

	my @tus;
	for (1..$num_tus) {
		my $buf = read_all($client, 8);
		my $file_name_sz = unpack("Q", $buf);

		my $file_name = read_all($client, $file_name_sz);

		$buf = read_all($client, 8);
		my $num_lines = unpack("Q", $buf);

		push @tus, { filename => $file_name, lines => $num_lines };
	}

	$self->{tus} = \@tus;
	return \@tus;
}

sub get_execution_data {
	my ($self) = @_;
	my $client = $self->{client_socket};
	my @tus = @{ $self->{tus} };

	my @data;
	for (@tus) {
		my $num_lines = $_->{lines};

		my $buf = read_all($client, 8 * $num_lines);
		my @data_tmp = unpack("Q$num_lines", $buf);

		push @data, [@data_tmp];
	}

	# Send an 'ok' response
	$client->syswrite("\x01", 1);

	return \@data;
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

sub DESTROY {
	my ($self) = @_;

	close($self->{viewer_socket});
	unlink "viewer_test.socket";
}

1;
