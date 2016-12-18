#
# Test that we can count an executing program as its running.
#
use strict;
use warnings;
use Test::More tests => 26;
use Time::HiRes qw( time usleep );
use t::shm;

my $tmp_dir = t::tmpdir->new();

my $child_pid = fork();
if ($child_pid == 0) {
	# Child.
	exec ("$tmp_dir/program", "45") or die $!;
}

# Give the forked child time to set up, but no longer than 1.0 seconds.
my $start = time;
my @procfiles;
do {
	@procfiles = glob("$ENV{CITRUN_PROCDIR}/program_*");
} while (scalar @procfiles == 0 && (time - $start) < 1.0);

is scalar @procfiles,	1,	"is one file in procdir";

my $shm = t::shm->new($procfiles[0]);

my $last_total = 0;
for (0..24) {
	usleep 100 * 1000;
	my $total = 0;

	for (0..2) {
		my $execs = $shm->execs_for($_);
		$total += $_ for (@$execs);
	}

	cmp_ok $total, '>', $last_total, "is total line count increasing";
	$last_total = $total;
}

kill 'TERM', $child_pid;
wait;
