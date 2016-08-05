use strict;
use Expect;
use Test::More tests => 1;
use Test::Project;

my $project = Test::Project->new();

$project->add_src(<<EOF);
int
main(void)
{
	while (1);
	return 0;
}
EOF
$project->compile();

my $exp = Expect->spawn("src/citrun-term");
my $waiting = "Waiting for connection on $ENV{CITRUN_SOCKET}";
ok(1) if (defined $exp->expect(undef, ($waiting)));

$project->run();
$exp->expect(undef, ("program"));

$project->kill();
$project->wait();

$exp->soft_close();
