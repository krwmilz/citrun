use strict;
use SCV::Project;
use Test::More tests => 3;
use Test::Differences;

my $project = SCV::Project->new();
unified_diff;

$project->add_src(<<EOF);
#include <stdlib.h>

int
main(int argc, char *argv[])
{
	if (argc == 1)
		return 1;
	else
		exit(14);

	if (argc == 2) {
		return 5;
	}
	else if (argc == 3) {
		return 0;
	}
	else {
		exit(0);
	}
}
EOF

$project->compile();

my $inst_src_good = <<EOF;
#include <stdlib.h>

int
main(int argc, char *argv[])
{libscv_init();
	if ((++_scv_lines[6], argc == 1))
		return (++_scv_lines[7], 1);
	else
		(++_scv_lines[9], exit(14));

	if ((++_scv_lines[11], argc == 2)) {
		return (++_scv_lines[12], 5);
	}
	else if ((++_scv_lines[14], argc == 3)) {
		return (++_scv_lines[15], 0);
	}
	else {
		(++_scv_lines[18], exit(0));
	}
}
EOF

my $inst_src = $project->instrumented_src();
ok( $inst_src );

eq_or_diff $inst_src, $inst_src_good, "instrumented source comparison";

$project->run();
my ($ret) = $project->wait();
is($ret, 1, "instrumented program check");
