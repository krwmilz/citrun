package Test::Viewer;
use strict;

use IO::Socket::UNIX;
use List::MoreUtils qw( each_array );
use Test::More;

my $viewer_socket_name = "citrun-test.socket";

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	my $viewer_socket = IO::Socket::UNIX->new(
		Type => SOCK_STREAM(),
		Local => $viewer_socket_name,
		Listen => 1,
	);
	die "socket error: $!\n" unless ($viewer_socket);

	$self->{viewer_socket} = $viewer_socket;
	return $self;
}

sub accept {
	my ($self) = @_;

	# Accept a new connection on the listening viewer socket.
	my $socket = $self->{viewer_socket};

	my $client = $socket->accept();
	$self->{client_socket} = $client;

	# Read the total number of instrumented translation units.
	my $buf = read_all($client, 8);
	$self->{num_tus} = unpack("Q", $buf);

	# Read three 4 byte pid_t's
	$buf = read_all($client, 12);
	($self->{pid}, $self->{ppid}, $self->{pgrp}) = unpack("L3", $buf);

	# Always sanity check these.
	cmp_ok( $self->{pid},	">",	1,	"pid lower bound check" );
	cmp_ok( $self->{pid},	"<",	100000,	"pid upper bound check" );
	cmp_ok( $self->{ppid},	">",	1,	"ppid lower bound check" );
	cmp_ok( $self->{ppid},	"<",	100000,	"ppid upper bound check" );
	cmp_ok( $self->{pgrp},	">",	1,	"pgrp lower bound check" );
	cmp_ok( $self->{pgrp},	"<",	100000,	"pgrp upper bound check" );

	# Read the static translation unit information.
	my @tus;
	for (1..$self->{num_tus}) {
		# Size of absolute file path.
		my $buf = read_all($client, 8);
		my $file_name_sz = unpack("Q", $buf);

		# Absolute file path.
		my $file_name = read_all($client, $file_name_sz);

		# Total number of lines in primary source file.
		$buf = read_all($client, 4);
		my $num_lines = unpack("L", $buf);

		# Number of instrumentation sites in primary source file.
		$buf = read_all($client, 4);
		my $inst_sites = unpack("L", $buf);

		# Keep this in order so it's easy to fetch dynamic data.
		push @tus, [ $file_name, $num_lines, $inst_sites ];
	}
	$self->{tus} = \@tus;
}

sub get_dynamic_data {
	my ($self) = @_;

	my $client = $self->{client_socket};
	my %data;

	for my $tu (@{ $self->{tus} }) {
		my $num_lines = $tu->[1];
		my $buf = read_all($client, 8 * $num_lines);
		my @data_tmp = unpack("Q$num_lines", $buf);

		$data{$tu->[0]} = \@data_tmp;
	}

	# Send an 'ok' response
	$client->syswrite("\x01", 1);

	return \%data;
}

sub cmp_static_data {
	my ($self, $known_good) = @_;

	# Sort these alphabetically by file name (field 0).
	my @sorted_tus = sort { $a->[0] cmp $b->[0] } @{ $self->{tus} };

	# Walk two lists at the same time
	# http://stackoverflow.com/questions/822563/how-can-i-iterate-over-multiple-lists-at-the-same-time-in-perl
	my $it = each_array( @$known_good, @sorted_tus );
	while ( my ($x, $y) = $it->() ) {
		like( $y->[0],	qr/.*$x->[0]/,	"$x->[0]: filename check" );
		is ( $y->[1],	$x->[1],	"$x->[0]: total lines check" );

		# Check instrumented sites ranges
		cmp_ok ( $y->[2], ">", $x->[2] - 25, "$x->[0]: instr sites check lower" );
		cmp_ok ( $y->[2], "<", $x->[2] + 25, "$x->[0]: instr sites check upper" );
	}
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
	unlink $viewer_socket_name;
}

1;
