use strict;
use warnings;

use Cwd;
use File::Which;
use Expect;
use File::Temp qw( tempdir );
use List::MoreUtils qw ( each_array );
use Test::More tests => 238;
use Time::HiRes qw( time );

use Test::Package;
use Test::Viewer;


# Verify that Vim under citrun tests successfully and then cross check that the
# data structures instrumented inside Vim are consistent with known good values.

# Download: Vim 7.4 from vim.org.
my $vim_url = "ftp://ftp.vim.org/pub/vim/unix/";
my $package = Test::Package->new("vim-7.4.tar.bz2", $vim_url, "tar xjf");

# Dependencies: gtk and curl are needed for consistent builds.
$package->dependencies("citrun", "gtk", "curl");

# Configure.
my $srcdir = $package->dir() . "/vim74/src";
system("citrun-wrap make -C $srcdir config") == 0 or die "citrun-wrap make config failed";

# Compile.
system("citrun-wrap make -C $srcdir -j8 myself") == 0 or die "citrun-wrap make failed";

# Test: need to use expect because Vim needs a tty to test correctly.
my $exp = Expect->spawn("make", "-C", "$srcdir/testdir");
$exp->expect(undef, ("ALL DONE"));
system("resize");

# Verify: instrumented data structures are consistent.
$ENV{CITRUN_SOCKET} = getcwd . "/citrun-test.socket";
$exp = Expect->spawn("$srcdir/vim");

my $viewer = Test::Viewer->new();
$viewer->accept();

my $runtime_metadata = $viewer->get_metadata();
is( $runtime_metadata->{num_tus}, 55,		"vim translation unit count" );
cmp_ok( $runtime_metadata->{pid}, ">", 1,	"vim pid lower bound check" );
cmp_ok( $runtime_metadata->{pid}, "<", 100000,	"vim pid upper bound check" );
cmp_ok( $runtime_metadata->{ppid}, ">", 1,	"vim ppid lower bound check" );
cmp_ok( $runtime_metadata->{ppid}, "<", 100000,	"vim ppid upper bound check" );
cmp_ok( $runtime_metadata->{pgrp}, ">", 1,	"vim pgrp lower bound check" );
cmp_ok( $runtime_metadata->{pgrp}, "<", 100000,	"vim pgrp upper bound check" );

my $tus = $runtime_metadata->{tus};
my @sorted_tus = sort { $a->{filename} cmp $b->{filename} } @$tus;

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

# Walk two lists at the same time
# http://stackoverflow.com/questions/822563/how-can-i-iterate-over-multiple-lists-at-the-same-time-in-perl
my $it = each_array( @known_good, @sorted_tus );
while ( my ($x, $y) = $it->() ) {
	like( $y->{filename},	qr/.*$x->[0]/,	"vim $x->[0]: filename check" );
	is ( $y->{lines},	$x->[1],	"vim $x->[0]: total lines check" );

	# Check instrumented sites as a range
	cmp_ok ( $y->{inst_sites}, ">", $x->[2] - 5, "vim $x->[0]: instrumented sites check lower" );
	cmp_ok ( $y->{inst_sites}, "<", $x->[2] + 5, "vim $x->[0]: instrumented sites check upper" );
}

print STDERR ">>> START\n";
# Lets see how long it takes to do 60 data calls
for (1..60) {
	my $data1 = $viewer->get_execution_data($tus);
	print STDERR ">>> LOOP\n";
}
print STDERR ">>> END\n";

$exp->hard_close();
$viewer->close();

$exp = Expect->spawn("$srcdir/xxd/xxd");
$viewer->accept();

$runtime_metadata = $viewer->get_metadata();
is( $runtime_metadata->{num_tus}, 1,		"xxd translation unit count" );
cmp_ok( $runtime_metadata->{pid}, ">", 1,	"xxd pid lower bound check" );
cmp_ok( $runtime_metadata->{pid}, "<", 100000,	"xxd pid upper bound check" );
cmp_ok( $runtime_metadata->{ppid}, ">", 1,	"xxd ppid lower bound check" );
cmp_ok( $runtime_metadata->{ppid}, "<", 100000,	"xxd ppid upper bound check" );
cmp_ok( $runtime_metadata->{pgrp}, ">", 1,	"xxd pgrp lower bound check" );
cmp_ok( $runtime_metadata->{pgrp}, "<", 100000,	"xxd pgrp upper bound check" );

$tus = $runtime_metadata->{tus};
@sorted_tus = sort { $a->{filename} cmp $b->{filename} } @$tus;

@known_good = (
	# file name		lines	instrumented sites
	[ "src/xxd/xxd.c",	851,	277 ],
);

$it = each_array( @known_good, @sorted_tus );
while ( my ($x, $y) = $it->() ) {
	like( $y->{filename},	qr/.*$x->[0]/,	"xxd $x->[0]: filename check" );
	is ( $y->{lines},	$x->[1],	"xxd $x->[0]: total lines check" );

	# Check instrumented sites as a range
	cmp_ok ( $y->{inst_sites}, ">", $x->[2] - 5, "xxd $x->[0]: instrumented sites check lower" );
	cmp_ok ( $y->{inst_sites}, "<", $x->[2] + 5, "xxd $x->[0]: instrumented sites check upper" );
}

$exp->hard_close();
