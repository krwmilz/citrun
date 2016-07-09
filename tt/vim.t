use strict;
use warnings;

use Cwd;
use Expect;
use Test::More;
use Time::HiRes qw( time usleep );

my $num_tests = 271;
$num_tests = 275 if ($^O eq "darwin");
plan tests => $num_tests;

use Test::Package;
use Test::Report;
use Test::Viewer;

# Download: Vim 7.4.
my $vim_url = "ftp://ftp.vim.org/pub/vim/unix/";
my $package = Test::Package->new("vim-7.4.tar.bz2", $vim_url, "tar xjf");
$package->dependencies("citrun");

sub time_expect {
	my $start = time;
	my $exp = Expect->spawn(@_);
	$exp->expect(undef, ("ALL DONE"));
	system("resize");
	return time - $start;
}

# New end to end report.
my $report = Test::Report->new("VIM", $num_tests);
$report->add("desc", "configure time (sec)");
$report->add("desc", "compile time (sec)");
$report->add("desc", "vim size (b)");
$report->add("desc", "xxd size (b)");
$report->add("desc", "test time (sec)");

my $srcdir = $package->set_srcdir("/vim74/src");

# Patch: Vim doesn't compile natively on OSX.
my $cwd = getcwd;
$package->patch("patch -p2 < $cwd/tt/patches/vim_osx.diff") if ($^O eq "darwin");

# Vanilla configure and compile.
$report->add("vanilla", $package->configure("./configure --enable-gui=no"));
$report->add("vanilla", $package->compile("make -j8 all"));

$report->add("vanilla", $package->get_file_size("/vim"));
$report->add("vanilla", $package->get_file_size("/xxd/xxd"));
#$package->copy_file("auto/config.log", "config.log.vanilla");

# Vanilla test.
$report->add("vanilla", time_expect("make", "-C", "$srcdir/testdir"));

# Clean up before rebuild.
$package->clean("make distclean");

# Instrumented configure and compile.
$report->add("citrun", $package->inst_configure());
$report->add("citrun", $package->inst_compile());

$report->add("citrun", $package->get_file_size("/vim"));
$report->add("citrun", $package->get_file_size("/xxd/xxd"));

# Instrumented test.
$report->add("citrun", time_expect("make", "-C", "$srcdir/testdir"));

# Verify: instrumented data structures are consistent.
my $viewer = Test::Viewer->new();
my $exp = Expect->spawn("$srcdir/vim");

my @known_good = (
	# file name		lines	instrumented sites
	[ "auto/pathdef.c",	11,	41	],
	[ "blowfish.c",		708,	84	],
	[ "buffer.c",		5828,	1328	],
	[ "charset.c",		2046,	429	],
	[ "diff.c",		2658,	625	],
	[ "digraph.c",		2540,	122	],
	[ "edit.c",		10246,	2276	],
	[ "eval.c",		24360,	4926	],
	[ "ex_cmds.c",		7682,	1674	],
	[ "ex_cmds2.c",		4415,	799	],
	[ "ex_docmd.c",		11511,	2234	],
	[ "ex_eval.c",		2296,	393	],
	[ "ex_getln.c",		6644,	1418	],
	[ "fileio.c",		10479,	1850	],
	[ "fold.c",		3458,	631	],
	[ "getchar.c",		5317,	925	],
	[ "hardcopy.c",		3682,	765	],
	[ "hashtab.c",		504,	95	],
	[ "if_cscope.c",	2611,	41	],
	[ "if_xcmdsrv.c",	1493,	272	],
	[ "main.c",		4156,	718	],
	[ "mark.c",		1832,	424	],
	[ "mbyte.c",		6315,	670	],
	[ "memfile.c",		1571,	274	],
	[ "memline.c",		5308,	972	],
	[ "menu.c",		2574,	415	],
	[ "message.c",		4945,	852	],
	[ "misc1.c",		10939,	2284	],
	[ "misc2.c",		6644,	917	],
	[ "move.c",		2922,	551	],
	[ "netbeans.c",		3942,	736	],
	[ "normal.c",		9623,	2037	],
	[ "ops.c",		6794,	1528	],
	[ "option.c",		11844,	1889	],
	[ "os_unix.c",		7365,	930	],
	[ "popupmnu.c",		730,	153	],
	[ "quickfix.c",		4251,	981	],
	[ "regexp.c",		8091,	2241	],
	[ "screen.c",		10474,	1749	],
	[ "search.c",		5608,	1299	],
	[ "sha256.c",		440,	92	],
	[ "spell.c",		16088,	3190	],
	[ "syntax.c",		9809,	1674	],
	[ "tag.c",		3940,	689	],
	[ "term.c",		6013,	730	],
	[ "ui.c",		3289,	565	],
	[ "undo.c",		3366,	742	],
	[ "version.c",		1405,	153	],
	[ "window.c",		6993,	1458	],
);

if ($^O eq "darwin") {
	my $to_insert = [ "os_mac_conv.c", 592, 1004 ];

	for my $i (0..(scalar @known_good - 1)) {
		next if ($known_good[$i]->[0] lt $to_insert->[0]);

		splice @known_good, $i, 0, ($to_insert);
		last;
	}
}

$viewer->accept();
is( $viewer->{num_tus}, scalar @known_good, "translation unit count" );

$viewer->cmp_static_data(\@known_good);

# Check that at least something has executed.
$viewer->cmp_dynamic_data();

$exp->hard_close();
$viewer->close();

#
# xxd
#

# Let xxd process something infinite.
$exp = Expect->spawn("$srcdir/xxd/xxd", "/dev/random", "/dev/null");

$viewer->accept();
is( $viewer->{num_tus}, 1, "xxd translation unit count" );

@known_good = (
	# file name		lines	instrumented sites
	[ "src/xxd/xxd.c",	851,	277 ],
);
$viewer->cmp_static_data(\@known_good);

for (1..60) {
	usleep(1000);
	$viewer->cmp_dynamic_data();
}

$exp->hard_close();
