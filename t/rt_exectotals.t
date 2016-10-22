#
# Test that we can count an executing program as its running.
#
use strict;
use warnings;
use Test::More tests => 100;
use Time::HiRes qw( usleep );
use tlib::program;
use tlib::shm;

my $child_pid = fork();
if ($child_pid == 0) {
	# Child.
	exec ("tlib/program/program", "45") or die $!;
}

# Give the runtime time to set up.
sleep 1;
my $shm = tlib::shm->new();

my $last_total = 0;
for (0..99) {
	usleep 10 * 1000;
	my $total = 0;

	for (0..2) {
		my $execs = $shm->execs_for($_);
		$total += $_ for (@$execs);
	}
	cmp_ok $total, '>', $last_total, "new total > old total";
}

kill 'TERM', $child_pid;
wait;
