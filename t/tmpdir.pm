package t::tmpdir;
use strict;
use warnings;
use File::Copy;
use File::Temp qw( tempdir );

sub new {
	my $tmp_dir = tempdir( CLEANUP => 1 );
	$ENV{CITRUN_PROCDIR} = "$tmp_dir/procdir/";

	copy("t/program/Makefile", $tmp_dir);
	copy("t/program/main.c", $tmp_dir);
	copy("t/program/print.c", $tmp_dir);
	copy("t/program/fib.c", $tmp_dir);

	system("src/citrun-wrap make -C $tmp_dir");

	return $tmp_dir;
}

1;
