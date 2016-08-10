use strict;
use Expect;
use Test::More tests => 1;
use Test::Project;

my $project = Test::Project->new();

my $exp = Expect->spawn("citrun-term");
my $waiting = "Waiting for connection on $ENV{CITRUN_SOCKET}";
ok(1) if (defined $exp->expect(undef, ($waiting)));

$project->run(45);
$exp->expect(undef, ("program"));

$project->kill();
$project->wait();

$exp->soft_close();
