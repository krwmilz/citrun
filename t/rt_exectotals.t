#
# Test that we can count an executing program as its running.
#
use strict;
use warnings;
use Test::More tests => 50;
use Time::HiRes qw( usleep );
use t::program;
use t::shm;

my $child_pid = fork();
if ($child_pid == 0) {
	# Child.
	exec ("t/program/program", "45") or die $!;
}

# Give the runtime time to set up.
sleep 1;
my $shm = t::shm->new();

my $last_total = 0;
for (0..49) {
	usleep 100 * 1000;
	my $total = 0;

	for (0..2) {
		my $execs = $shm->execs_for($_);
		$total += $_ for (@$execs);
	}

	cmp_ok $total, '>', $last_total, "new total > old total";
	$last_total = $total;
}

kill 'TERM', $child_pid;
wait;
