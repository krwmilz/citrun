#
# A little frontend for t::shm that prints the list of translation units.
#
use strict;
use warnings;
use t::shm;

open(my $out, '>', 'tu_list.out') or die $!;
my $shm = t::shm->new($ARGV[0]);

select $out;

my $transl_units = $shm->{translation_units};
for (@$transl_units) {
	my %tu = %$_;

	print "$tu{comp_file_name} $tu{size}\n";
}
