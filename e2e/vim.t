use strict;

use Cwd;
use File::Which;
use Expect;
use File::Temp qw( tempdir );
use List::MoreUtils qw ( each_array );
use SCV::Viewer;
use Test::More tests => 227;
use Time::HiRes qw( time );

#
# This uses tools installed from a package, not the in tree build!
#

# XXX: check that citrun is installed in OS independent way

#
# Download source, extract, configure and compile
#
my $tmpdir = tempdir( CLEANUP => 1 );
my $vim_src = "ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2";
system("cd $tmpdir && curl -O $vim_src") == 0 or die "download failed";
system("cd $tmpdir && tar xjf vim-7.4.tar.bz2") == 0 or die "extract failed";

my $srcdir = "$tmpdir/vim74/src";
system("citrun-wrap make -C $srcdir config") == 0 or die "citrun-wrap make config failed";

# Remove last instrumented node from configure run
system("rm $srcdir/LAST_NODE");
system("citrun-wrap make -C $srcdir -j8 myself") == 0 or die "citrun-wrap make failed";

#
# Check that the native test suite can pass, validating that the instrumentation
# hasn't broken the intent of the program.
#
my $exp = Expect->spawn("make", "-C", "$srcdir/testdir");
$exp->expect(undef, ("ALL DONE"));
# Unfuck the terminal after the testsuite is done
system("resize");

#
# Make sure the instrumentation for Vim is working correctly
#
my $viewer = SCV::Viewer->new();
$ENV{CITRUN_SOCKET} = getcwd . "/SCV::Viewer.socket";

$exp = Expect->spawn("$srcdir/vim");
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

# Element order: filename, total lines in file, instrumented sites
# Use this to regenerate:
# print STDERR "[ \"$_->{filename}\", $_->{lines}, $_->{inst_sites} ],\n" for (@sorted_tus);
my @known_good = (
	[ "auto/pathdef.c", 11, 71 ],
	[ "blowfish.c", 708, 121 ],
	[ "buffer.c", 5828, 1368 ],
	[ "charset.c", 2046, 463 ],
	[ "diff.c", 2658, 660 ],
	[ "digraph.c", 2540, 152 ],
	[ "edit.c", 10246, 2363 ],
	[ "eval.c", 24360, 5009 ],
	[ "ex_cmds.c", 7682, 1741 ],
	[ "ex_cmds2.c", 4415, 799 ],
	[ "ex_docmd.c", 11511, 2324 ],
	[ "ex_eval.c", 2296, 423 ],
	[ "ex_getln.c", 6644, 1508 ],
	[ "fileio.c", 10479, 1857 ],
	[ "fold.c", 3458, 667 ],
	[ "getchar.c", 5317, 994 ],
	[ "gui.c", 5539, 1047 ],
	[ "gui_beval.c", 1344, 237 ],
	[ "gui_gtk.c", 1962, 531 ],
	[ "gui_gtk_f.c", 845, 189 ],
	[ "gui_gtk_x11.c", 6058, 1107 ],
	[ "hardcopy.c", 3682, 800 ],
	[ "hashtab.c", 504, 126 ],
	[ "if_cscope.c", 2611, 71 ],
	[ "if_xcmdsrv.c", 1493, 415 ],
	[ "main.c", 4156, 840 ],
	[ "mark.c", 1832, 455 ],
	[ "mbyte.c", 6315, 841 ],
	[ "memfile.c", 1571, 304 ],
	[ "memline.c", 5308, 1028 ],
	[ "menu.c", 2574, 533 ],
	[ "message.c", 4945, 957 ],
	[ "misc1.c", 10939, 2340 ],
	[ "misc2.c", 6644, 997 ],
	[ "move.c", 2922, 585 ],
	[ "netbeans.c", 3942, 841 ],
	[ "normal.c", 9623, 2141 ],
	[ "ops.c", 6794, 1583 ],
	[ "option.c", 11844, 2014 ],
	[ "os_unix.c", 7365, 1124 ],
	[ "popupmnu.c", 730, 183 ],
	[ "pty.c", 426, 89 ],
	[ "quickfix.c", 4251, 1016 ],
	[ "regexp.c", 8091, 2284 ],
	[ "screen.c", 10474, 1881 ],
	[ "search.c", 5608, 1332 ],
	[ "sha256.c", 440, 122 ],
	[ "spell.c", 16088, 3168 ],
	[ "syntax.c", 9809, 1824 ],
	[ "tag.c", 3940, 723 ],
	[ "term.c", 6013, 832 ],
	[ "ui.c", 3289, 733 ],
	[ "undo.c", 3366, 777 ],
	[ "version.c", 1405, 196 ],
	[ "window.c", 6993, 1525 ],
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
