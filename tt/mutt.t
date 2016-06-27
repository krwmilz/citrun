use strict;
use warnings;

use Expect;
use List::MoreUtils qw( each_array );
use Test::More tests => 391;
use Time::HiRes qw( time );

use Test::Package;
use Test::Viewer;

# Download: Mutt 1.6.1, depends on nothing (?).
my $mutt_url = "ftp://ftp.mutt.org/pub/mutt/";
my $package = Test::Package->new("mutt-1.6.1.tar.gz", $mutt_url, "tar xzf");
$package->dependencies("citrun");

my @desc = ("configure time (sec)", "compile time (sec)", "mutt size (b)");
my (@vanilla, @citrun);

my $srcdir = $package->set_srcdir("/mutt-1.6.1");

# Vanilla configure and compile.
$vanilla[0] = $package->configure("./configure");
$vanilla[1] = $package->compile("make -j4 all");

$vanilla[2] = $package->get_file_size("/mutt");

# Clean up before rebuild.
$package->clean("make distclean");

# Instrumented configure and compile.
$citrun[0] = $package->inst_configure();
$citrun[1] = $package->inst_compile();

$citrun[2] = $package->get_file_size("/mutt");

# Verify: instrumented data structures are consistent.
my $viewer = Test::Viewer->new();
my $exp = Expect->spawn("$srcdir/mutt");

$viewer->accept();
is( $viewer->{num_tus}, 96, "translation unit count" );

my @known_good = (
	# file name		lines	instrumented sites
	[ "/addrbook.c",	246,	102 ],
	[ "/alias.c",		658,	266 ],
	[ "/ascii.c",		107,	42 ],
	[ "/attach.c",		1043,	454 ],
	[ "/base64.c",		123,	42 ],
	[ "/browser.c",		1267,	342 ],
	[ "/buffy.c",		629,	234 ],
	[ "/charset.c",		680,	179 ],
	[ "/color.c",		824,	260 ],
	[ "/commands.c",	1018,	358 ],
	[ "/complete.c",	199,	70 ],
	[ "/compose.c",		1345,	375 ],
	[ "/conststrings.c",	32,	0 ],
	[ "/copy.c",		962,	403 ],
	[ "/crypt-mod-pgp-classic.c",	138,56 ],
	[ "/crypt-mod-smime-classic.c",	119,49 ],
	[ "/crypt-mod.c",	59,	32 ],
	[ "/crypt.c",		1121,	461 ],
	[ "/cryptglue.c",	396,	107 ],
	[ "/curs_lib.c",	1046,	323 ],
	[ "/curs_main.c",	2349,	545 ],
	[ "/date.c",		191,	59 ],
	[ "/dotlock.c",		759,	139 ],
	[ "/edit.c",		491,	212 ],
	[ "/editmsg.c",		235,	97 ],
	[ "/enter.c",		772,	267 ],
	[ "/filter.c",		184,	103 ],
	[ "/flags.c",		384,	129 ],
	[ "/from.c",		199,	138 ],
	[ "/getdomain.c",	70,	40 ],
	[ "/gnupgparse.c",	446,	149 ],
	[ "/group.c",		209,	117 ],
	[ "/handler.c",		1845,	612 ],
	[ "/hash.c",		179,	83 ],
	[ "/hdrline.c",		764,	313 ],
	[ "/headers.c",		214,	124 ],
	[ "/help.c",		380,	187 ],
	[ "/history.c",		320,	122 ],
	[ "/hook.c",		545,	186 ],
	[ "/init.c",		3285,	1161 ],
	[ "/intl/bindtextdom.c",370,	54 ],
	[ "/intl/dcgettext.c",	59,	1 ],
	[ "/intl/dcigettext.c",	1260,	133 ],
	[ "/intl/dcngettext.c",	61,	1 ],
	[ "/intl/dgettext.c",	60,	1 ],
	[ "/intl/dngettext.c",	62,	1 ],
	[ "/intl/explodename.c",193,	28 ],
	[ "/intl/finddomain.c",	199,	38 ],
	[ "/intl/gettext.c",	65,	2 ],
	[ "/intl/intl-compat.c",167,	19 ],
	[ "/intl/l10nflist.c",	406,	100 ],
	[ "/intl/loadmsgcat.c",	568,	61 ],
	[ "/intl/localealias.c",405,	84 ],
	[ "/intl/ngettext.c",	69,	2 ],
	[ "/intl/plural.c",	414,	83 ],
	[ "/intl/textdomain.c",	143,	14 ],
	[ "/keymap.c",		1146,	387 ],
	[ "/lib.c",		1086,	360 ],
	[ "/main.c",		1225,	353 ],
	[ "/mbox.c",		1269,	446 ],
	[ "/mbyte.c",		569,	68 ],
	[ "/menu.c",		1082,	273 ],
	[ "/mh.c",		2351,	726 ],
	[ "/muttlib.c",		1958,	555 ],
	[ "/mx.c",		1629,	455 ],
	[ "/pager.c",		2817,	631 ],
	[ "/parse.c",		1648,	588 ],
	[ "/patchlist.c",	12,	28 ],
	[ "/pattern.c",		1546,	549 ],
	[ "/pgp.c",		1866,	722 ],
	[ "/pgpinvoke.c",	358,	116 ],
	[ "/pgpkey.c",		1045,	393 ],
	[ "/pgplib.c",		253,	71 ],
	[ "/pgpmicalg.c",	212,	102 ],
	[ "/pgppacket.c",	232,	75 ],
	[ "/postpone.c",	748,	232 ],
	[ "/query.c",		543,	223 ],
	[ "/recvattach.c",	1274,	428 ],
	[ "/recvcmd.c",		950,	297 ],
	[ "/resize.c",		80,	47 ],
	[ "/rfc1524.c",		594,	203 ],
	[ "/rfc2047.c",		924,	315 ],
	[ "/rfc2231.c",		384,	136 ],
	[ "/rfc3676.c",		390,	140 ],
	[ "/rfc822.c",		919,	245 ],
	[ "/safe_asprintf.c",	96,	35 ],
	[ "/score.c",		196,	74 ],
	[ "/send.c",		1953,	660 ],
	[ "/sendlib.c",		2890,	972 ],
	[ "/signal.c",		254,	85 ],
	[ "/smime.c",		2280,	802 ],
	[ "/sort.c",		343,	133 ],
	[ "/status.c",		309,	148 ],
	[ "/system.c",		142,	65 ],
	[ "/thread.c",		1431,	386 ],
	[ "/url.c",		325,	164 ],
);
$viewer->cmp_static_data(\@known_good);

my $start = time;
$viewer->get_dynamic_data() for (1..60);
my $data_call_dur = time - $start;

$exp->hard_close();
$viewer->close();


# Write report.
#

my @diff;
my $it = each_array( @vanilla, @citrun );
while ( my ($x, $y) = $it->() ) {
	push @diff, $y * 100.0 / $x - 100.0;
}

format STDOUT =

MUTT E2E REPORT
===============

     @<<<<<<<<<<<<<< @##.## sec
"60 data calls:", $data_call_dur

SCALAR COMPARISONS
                                      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
"vanilla", "citrun", "diff (%)"
     ---------------------------------------------------------------------
~~   @<<<<<<<<<<<<<<<<<<<<<<<<<<      @>>>>>>>>>   @>>>>>>>>>     @>>>>>>>
shift(@desc), shift(@vanilla), shift(@citrun), shift(@diff)

DIFF COMPARISONS

.

write;
