#!/usr/bin/perl
#
# A little frontend for t::mem that prints the list of translation units.
#
# Usage: write_tus.pl output_file memory_file
#
use strict;
use warnings;

use t::mem;

open( my $out, '>', $ARGV[0] ) or die $!;
my $shm = t::mem->new( $ARGV[1] );

my $tus = $shm->{trans_units};
for (sort keys %$tus) {
	my $tu = $tus->{$_};

	print $out "$tu->{comp_file_name} $tu->{size}\n";
}
