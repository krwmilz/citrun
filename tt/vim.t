use strict;
use warnings;

use Cwd;
use Expect;
use File::Which;
use List::MoreUtils qw( each_array );
use Test::More tests => 238;
use Time::HiRes qw( time );

use Test::Package;
use Test::Viewer;

# Verify that Vim under citrun tests successfully and then cross check that the
# data structures instrumented inside Vim are consistent with known good values.

# Declare this early. Instrumented binaries will try connecting w/o issuing warn
my $viewer = Test::Viewer->new();

# Download: Vim 7.4 from vim.org.
my $vim_url = "ftp://ftp.vim.org/pub/vim/unix/";
my $package = Test::Package->new("vim-7.4.tar.bz2", $vim_url, "tar xjf");

# Dependencies: gtk and curl are needed for consistent builds.
$package->dependencies("citrun", "gtk", "curl");

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

my $srcdir = $package->dir() . "/vim74/src";

# Vanilla configure.
$scalar_vanilla[0] = $package->configure("make -C $srcdir config");
#$package->copy_file("auto/config.log", "config.log.vanilla");

# Vanilla compile.
$scalar_vanilla[1] = $package->compile("make -C $srcdir -j4 all");

$scalar_vanilla[2] = ((stat "$srcdir/vim")[7]);
$scalar_vanilla[3] = ((stat "$srcdir/xxd/xxd")[7]);

# Vanilla test.
$scalar_vanilla[4] = time_expect("make", "-C", "$srcdir/testdir");

# Clean up before rebuild.
system("make -C $srcdir distclean");

# Instrumented configure.
$scalar_citrun[0] = $package->inst_configure();

# Instrumented compile.
$scalar_citrun[1] = $package->inst_compile();

$scalar_citrun[2] = ((stat "$srcdir/vim")[7]);
$scalar_citrun[3] = ((stat "$srcdir/xxd/xxd")[7]);

# Instrumented test.
$scalar_citrun[4] = time_expect("make", "-C", "$srcdir/testdir");

# Verify: instrumented data structures are consistent.
$ENV{CITRUN_SOCKET} = getcwd . "/citrun-test.socket";
my $exp = Expect->spawn("$srcdir/vim");

$viewer->accept();
is( $viewer->{num_tus}, 55, "translation unit count" );

my @known_good = (
	# file name		lines	instrumented sites
	[ "auto/pathdef.c",	11,	71	],
	[ "blowfish.c",		708,	117	],
	[ "buffer.c",		5828,	1368	],
	[ "charset.c",		2046,	462	],
	[ "diff.c",		2658,	660	],
	[ "digraph.c",		2540,	152	],
	[ "edit.c",		10246,	2363	],
	[ "eval.c",		24360,	5000	],
	[ "ex_cmds.c",		7682,	1734	],
	[ "ex_cmds2.c",		4415,	798	],
	[ "ex_docmd.c",		11511,	2320	],
	[ "ex_eval.c",		2296,	423	],
	[ "ex_getln.c",		6644,	1498	],
	[ "fileio.c",		10479,	1846	],
	[ "fold.c",		3458,	664	],
	[ "getchar.c",		5317,	982	],
	[ "gui.c",		5539,	1045	],
	[ "gui_beval.c",	1344,	237	],
	[ "gui_gtk.c",		1962,	531	],
	[ "gui_gtk_f.c",	845,	189	],
	[ "gui_gtk_x11.c",	6058,	1103	],
	[ "hardcopy.c",		3682,	800	],
	[ "hashtab.c",		504,	126	],
	[ "if_cscope.c",	2611,	71	],
	[ "if_xcmdsrv.c",	1493,	413	],
	[ "main.c",		4156,	840	],
	[ "mark.c",		1832,	455	],
	[ "mbyte.c",		6315,	841	],
	[ "memfile.c",		1571,	304	],
	[ "memline.c",		5308,	1005	],
	[ "menu.c",		2574,	533	],
	[ "message.c",		4945,	950	],
	[ "misc1.c",		10939,	2319	],
	[ "misc2.c",		6644,	990	],
	[ "move.c",		2922,	585	],
	[ "netbeans.c",		3942,	837	],
	[ "normal.c",		9623,	2141	],
	[ "ops.c",		6794,	1564	],
	[ "option.c",		11844,	2012	],
	[ "os_unix.c",		7365,	1124	],
	[ "popupmnu.c",		730,	183	],
	[ "pty.c",		426,	89	],
	[ "quickfix.c",		4251,	1016	],
	[ "regexp.c",		8091,	2272	],
	[ "screen.c",		10474,	1859	],
	[ "search.c",		5608,	1332	],
	[ "sha256.c",		440,	122	],
	[ "spell.c",		16088,	3150	],
	[ "syntax.c",		9809,	1822	],
	[ "tag.c",		3940,	721	],
	[ "term.c",		6013,	832	],
	[ "ui.c",		3289,	718	],
	[ "undo.c",		3366,	777	],
	[ "version.c",		1405,	196	],
	[ "window.c",		6993,	1525	],
);
$viewer->cmp_static_data(\@known_good);

my $start = time;
$viewer->get_dynamic_data() for (1..60);
my $data_call_dur = time - $start;

$exp->hard_close();
$viewer->close();

#
# xxd
#

$exp = Expect->spawn("$srcdir/xxd/xxd");

$viewer->accept();
is( $viewer->{num_tus}, 1, "xxd translation unit count" );

@known_good = (
	# file name		lines	instrumented sites
	[ "src/xxd/xxd.c",	851,	277 ],
);
$viewer->cmp_static_data(\@known_good);

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

     @<<<<<<<<<<<<<< @##.## sec
"60 data calls:", $data_call_dur

SCALAR COMPARISONS:
                                      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
"vanilla", "citrun", "diff (%)"
     ---------------------------------------------------------------------
~~   @<<<<<<<<<<<<<<<<<<<<<<<<<<      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
shift(@scalar_desc), shift(@scalar_vanilla), shift(@scalar_citrun), shift(@scalar_diff)

DIFF COMPARISONS:

.

write;
