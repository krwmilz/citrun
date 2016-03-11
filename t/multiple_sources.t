use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 1;
use Test::Differences;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();
unified_diff;

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
