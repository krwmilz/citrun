package t::mem;

use strict;
use warnings;

use POSIX;
use Sys::Mmap;
use autodie;

our $os_allocsize = POSIX::sysconf(POSIX::_SC_PAGESIZE);

sub get_mem {
	my ($self, $procfile) = @_;

	open( FH, "<", $procfile );

	$self->{mem} = '';
	mmap( $self->{mem}, 0, PROT_READ, MAP_SHARED, FH ) or die "mmap: $!";
	$self->{size} = length $self->{mem};

	close FH;

}

1;
