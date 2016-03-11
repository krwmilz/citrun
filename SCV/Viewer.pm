package SCV::Viewer;
use strict;

use IO::Socket::UNIX;
use Test;

sub new {
	my ($class, $tmp_dir) = @_;
	my $self = {};
	bless ($self, $class);

	my $viewer_socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM(),
		Local => "/tmp/viewer_test.socket",
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

	print STDERR "accept(): accepted client\n";
}

sub request_data {
	my ($self) = @_;
	my $client = $self->{client_socket};

	$client->syswrite("\x00", 1);

	my $buf = read_all($client, 8);
	my $file_name_sz = unpack("Q", $buf);

	my $file_name = read_all($client, $file_name_sz);

	$buf = read_all($client, 8);
	my $num_lines = unpack("Q", $buf);

	$buf = read_all($client, 8 * $num_lines);
	my @data = unpack("Q$num_lines", $buf);

	return ({ file_name => $file_name, data => \@data });
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
	unlink "/tmp/viewer_test.socket";
}

1;
