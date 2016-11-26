package t::tmpdir;
use strict;
use warnings;
use File::Temp qw( tempdir );

sub new {
	my $tmp_dir = tempdir( CLEANUP => 1 );
	$ENV{CITRUN_PROCDIR} = "$tmp_dir/procdir/";

	return $tmp_dir;
}

1;
