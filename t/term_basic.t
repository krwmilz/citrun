use strict;
use Test::More skip_all => "citrun_term not compiled";
use Expect;
use test::project;

my $project = test::project->new();

my $exp = Expect->spawn("citrun_term");
my $waiting = "Waiting for connection on $ENV{CITRUN_SOCKET}";
ok(1) if (defined $exp->expect(undef, ($waiting)));

$project->run(45);
$exp->expect(undef, ("program"));

$project->kill();
$project->wait();

$exp->soft_close();
