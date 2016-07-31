use strict;
use Test::More tests => 1;
use Test::Project;
use Test::Viewer;

my $project = Test::Project->new();
$ENV{CITRUN_SOCKET} = $project->tmpdir() . "/test.socket";
my $viewer = Test::Viewer->new();

$project->add_src(<<EOF
void second_func();

int
main(void)
{
	second_func();
	return 0;
}
EOF
);

$project->add_src(<<EOF
void third_func();

void
second_func(void)
{
	third_func();
	return;
}
EOF
);

$project->add_src(<<EOF
void
third_func(void)
{
	return;
}
EOF
);

$project->compile();
$project->run();

my ($ret, $err) = $project->wait();
is($ret, 0, "instrumented program check return code");
