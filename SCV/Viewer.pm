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
		Local => "SCV::Viewer.socket",
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

	# Next is the 3 4 byte pid_t's
	$buf = read_all($client, 12);
	my ($pid, $ppid, $pgrp) = unpack("L3", $buf);

	my $runtime_metadata = {
		num_tus => $num_tus,
		pid => $pid,
		ppid => $ppid,
		pgrp => $pgrp,
	};

	my @tus;
	for (1..$num_tus) {
		my $buf = read_all($client, 8);
		my $file_name_sz = unpack("Q", $buf);

		my $file_name = read_all($client, $file_name_sz);

		$buf = read_all($client, 4);
		my $num_lines = unpack("L", $buf);

		$buf = read_all($client, 4);
		my $inst_sites = unpack("L", $buf);

		push @tus, { filename => $file_name, lines => $num_lines, inst_sites => $inst_sites };
	}
	$runtime_metadata->{tus} = \@tus;

	return $runtime_metadata;
}

sub get_execution_data {
	my ($self, $tus) = @_;
	my $client = $self->{client_socket};

	my @data;
	for (@$tus) {
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

sub close {
	my ($self) = @_;
	close ($self->{client_socket});
}

sub DESTROY {
	my ($self) = @_;

	close($self->{viewer_socket});
	unlink "SCV::Viewer.socket";
}

1;
