use strict;
use warnings;

use Cwd;
use Expect;
use List::MoreUtils qw( each_array );
use Test::More;
use Time::HiRes qw( time );

my $num_tests = 333;
$num_tests = 337 if ($^O eq "darwin");
plan tests => $num_tests;

use Test::Package;
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

my @scalar_desc = ("configure time (sec)", "compile time (sec)", "vim size (b)",
	"xxd size (b)", "test time (sec)");
my @scalar_vanilla;
my @scalar_citrun;

my $srcdir = $package->set_srcdir("/vim74/src");

# Patch: Vim doesn't compile natively on OSX.
my $cwd = getcwd;
$package->patch("patch -p2 < $cwd/tt/patches/vim_osx.diff") if ($^O eq "darwin");

# Vanilla configure and compile.
$scalar_vanilla[0] = $package->configure("./configure --enable-gui=no");
$scalar_vanilla[1] = $package->compile("make -j8 all");

$scalar_vanilla[2] = $package->get_file_size("/vim");
$scalar_vanilla[3] = $package->get_file_size("/xxd/xxd");
#$package->copy_file("auto/config.log", "config.log.vanilla");

# Vanilla test.
$scalar_vanilla[4] = time_expect("make", "-C", "$srcdir/testdir");

# Clean up before rebuild.
$package->clean("make distclean");

# Instrumented configure and compile.
$scalar_citrun[0] = $package->inst_configure();
$scalar_citrun[1] = $package->inst_compile();

$scalar_citrun[2] = $package->get_file_size("/vim");
$scalar_citrun[3] = $package->get_file_size("/xxd/xxd");

# Instrumented test.
$scalar_citrun[4] = time_expect("make", "-C", "$srcdir/testdir");

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
	[ "if_xcmdsrv.c",	1493,	108	],
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

is( $viewer->{num_tus}, scalar @known_good, "translation unit count" );

$viewer->accept();
$viewer->cmp_static_data(\@known_good);

my ($data, $old_data) = (undef, undef);
for (1..60) {
	$old_data = $data;
	$data = $viewer->cmp_dynamic_data($old_data);
}

$exp->hard_close();
$viewer->close();

#
# xxd
#

$exp = Expect->spawn("$srcdir/xxd/xxd", "distfiles/vim-7.4.tar.bz2");

$viewer->accept();
is( $viewer->{num_tus}, 1, "xxd translation unit count" );

@known_good = (
	# file name		lines	instrumented sites
	[ "src/xxd/xxd.c",	851,	277 ],
);
$viewer->cmp_static_data(\@known_good);

for (1..60) {
	$old_data = $data;
	$data = $viewer->cmp_dynamic_data($old_data);
}

$exp->hard_close();

my @scalar_diff;
my $it = each_array( @scalar_vanilla, @scalar_citrun );
while ( my ($x, $y) = $it->() ) {
       push @scalar_diff, $y * 100.0 / $x - 100.0;
}

# Write report.
#
format STDOUT =

VIM E2E REPORT
==============

SCALAR COMPARISONS
                                      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
"vanilla", "citrun", "diff (%)"
     ---------------------------------------------------------------------
~~   @<<<<<<<<<<<<<<<<<<<<<<<<<<      @>>>>>>>>>   @>>>>>>>>>        @>>>>
shift(@scalar_desc), shift(@scalar_vanilla), shift(@scalar_citrun), shift(@scalar_diff)

DIFF COMPARISONS

.

write;
