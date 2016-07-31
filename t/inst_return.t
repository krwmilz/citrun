use strict;
use Test::More tests => 1;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
$ENV{CITRUN_SOCKET} = $project->tmpdir() . "/test.socket";
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF);
int foo() {
	return 0;
}

int main(void) {
	return 10;

	return 10 + 10;

	return foo();
}
EOF

$project->compile();
$project->run();

my ($ret) = $project->wait();
is($ret, 10, "instrumented program check");
