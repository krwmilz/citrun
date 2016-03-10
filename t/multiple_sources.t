use strict;
use SCV::Project;
use Test::More tests => 2;
use Test::Differences;

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

my $tmp_dir = $project->get_tmpdir();

my $inst_src_good = <<EOF;
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

#eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

my ($ret, $err) = $project->run();
is($ret, 0, "instrumented program check return code");
