package Test::Viewer;
use strict;

use IO::Socket::UNIX;
use List::MoreUtils qw( each_array );
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

	# Protocol defined in lib/runtime.c function send_static().
	#
	($self->{maj}, $self->{min}) = read_unpack($sock, 2, "C2");
	($self->{ntus}, $self->{nlines}) = read_unpack($sock, 8, "L2");
	@{ $self->{pids} } =	read_unpack($sock, 12, "L3");
	$self->{progname} =	read_all($sock, read_unpack($sock, 2, "S"));
	$self->{cwd} =		read_all($sock, read_unpack($sock, 2, "S"));

	my @tus;
	for (1..$self->{ntus}) {
		my $file_name = read_all($sock, read_unpack($sock, 2, "S"));
		my ($num_lines, $inst_sites) = read_unpack($sock, 8, "L2");

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
		# Check if there's any update.
		my $has_data = read_unpack($client, 1, "C");

		my $num_lines = $tu->[1];
		my @data_tmp;
		if ($has_data == 0) {
			# print STDERR "no data for tu $_\n";
			@data_tmp = (0) x $num_lines;
		}
		else {
			@data_tmp = read_unpack($client, 4 * $num_lines,
				"L$num_lines");
		}

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
		# For Vim and Mutt respectively.
		next if ($x->[0] eq "if_xcmdsrv.c" || $x->[0] eq "/conststrings.c");

		like( $y->[0],	qr/.*$x->[0]/,	"$x->[0]: filename check" );
		is ( $y->[1],	$x->[1],	"$x->[0]: total lines check" );

		# Check instrumented sites ranges
		cmp_ok ( $y->[2], ">", $x->[2] - 100, "$x->[0]: instr sites check lower" );
		cmp_ok ( $y->[2], "<", $x->[2] + 100, "$x->[0]: instr sites check upper" );
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
