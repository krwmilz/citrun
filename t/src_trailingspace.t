#
# Test that source files have no trailing whitespace.
#
use Test::More tests => 1;
use Test::TrailingSpace;

my $finder = Test::TrailingSpace->new(
	{
		root => '.',
		filename_regex => qr/\.(?:t|pm|pl|cc|h|sh|1)\z/,
	},
);

# Run test.
$finder->no_trailing_space("No trailing spaces found.");
