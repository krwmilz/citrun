#
# A little frontend for t::shm that prints the list of translation units.
#
use strict;
use warnings;
use t::shm;

open(my $out, '>', 'tu_list.out') or die $!;
my $shm = t::shm->new($ARGV[0]);

select $out;
$shm->print_tus();
