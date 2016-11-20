package t::tmpdir;
use strict;
use warnings;
use File::Temp qw( tempdir );

sub new {
	my $tmp_dir = tempdir( CLEANUP => 1 );
	$ENV{CITRUN_PROCFILE} = "$tmp_dir/procfile.shm";

	return $tmp_dir;
}

1;
