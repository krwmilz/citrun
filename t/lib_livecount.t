#
# Test that we can count an executing program as its running.
#
use strict;
use warnings;

use Time::HiRes qw( time usleep );
use t::shm;
use t::utils;
plan tests => 23;


my $dir = setup_projdir();

my $child_pid = fork();
if ($child_pid == 0) {
	# Child.
	exec ($dir->workdir . "/program", "45") or die $!;
}

usleep 500 * 1000;
my $shm_path = get_one_shmfile( $ENV{CITRUN_PROCDIR} );
my $shm = t::shm->new( $shm_path );

my %trans_units = %{ $shm->{trans_units} };

my $last_total = 0;
for (0..20) {
	usleep 1 * 1000;
	my $total = 0;

	for (keys %trans_units) {
		my $execs = $shm->get_buffers($_);
		$total += $_ for (@$execs);
	}

	cmp_ok $total, '>', $last_total, "is total line count increasing";
	$last_total = $total;
}

kill 'TERM', $child_pid;
wait;
