package t::shm;

use strict;
use warnings;

use POSIX;
use Sys::Mmap;
use autodie;

our $page_mask = POSIX::sysconf(POSIX::_SC_PAGESIZE) - 1;

sub get_mem {
	my ($self, $procfile) = @_;

	open( FH, "<", $procfile );

	mmap( $self->{mem}, 0, PROT_READ, MAP_SHARED, FH ) or die "mmap: $!";
	$self->{size} = length $self->{mem};

	close FH;
}

1;
