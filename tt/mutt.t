use strict;
use warnings;

use Expect;
use Test::More tests => 204;
use test::package;
use test::viewer;

my $package = test::package->new("mail/mutt");
my $viewer = test::viewer->new();

my $exp = Expect->spawn("/usr/ports/pobj/mutt-1.6.2/mutt-1.6.2/mutt");
$viewer->accept();
$viewer->cmp_static_data([
	# file name		lines	instrumented sites
	["/account.c", 241, 89],
	["/addrbook.c", 246, 98],
	["/alias.c", 658, 262],
	["/ascii.c", 107, 42],
	["/attach.c", 1043, 454],
	["/base64.c", 123, 42],
	["/bcache.c", 268, 105],
	["/browser.c", 1267, 439],
	["/buffy.c", 629, 239],
	["/charset.c", 680, 167],
	["/color.c", 824, 260],
	["/commands.c", 1019, 361],
	["/complete.c", 199, 77],
	["/compose.c", 1345, 375],
	["/conststrings.c", 75, 0],
	["/copy.c", 962, 399],
	["/crypt-mod-pgp-classic.c", 138, 56],
	["/crypt-mod-smime-classic.c", 119, 49],
	["/crypt-mod.c", 59, 32],
	["/crypt.c", 1121, 461],
	["/cryptglue.c", 396, 107],
	["/curs_lib.c", 1046, 323],
	["/curs_main.c", 2349, 555],
	["/date.c", 191, 59],
	["/edit.c", 491, 208],
	["/editmsg.c", 235, 97],
	["/enter.c", 772, 267],
	["/filter.c", 184, 103],
	["/flags.c", 401, 137],
	["/from.c", 199, 138],
	["/getdomain.c", 70, 40],
	["/gnupgparse.c", 446, 147],
	["/group.c", 209, 117],
	["/handler.c", 1845, 610],
	["/hash.c", 179, 83],
	["/hcache.c", 1242, 305],
	["/hdrline.c", 764, 309],
	["/headers.c", 214, 120],
	["/help.c", 380, 187],
	["/history.c", 320, 122],
	["/hook.c", 545, 198],
	["/imap/auth.c", 114, 53],
	["/imap/auth_anon.c", 77, 52],
	["/imap/auth_cram.c", 181, 77],
	["/imap/auth_login.c", 74, 52],
	["/imap/browse.c", 472, 188],
	["/imap/command.c", 1042, 344],
	["/imap/imap.c", 2041, 714],
	["/imap/message.c", 1308, 440],
	["/imap/utf7.c", 292, 96],
	["/imap/util.c", 852, 284],
	["/init.c", 3285, 1160],
	["/keymap.c", 1150, 391],
	["/lib.c", 1086, 360],
	["/main.c", 1249, 362],
	["/mbox.c", 1269, 446],
	["/mbyte.c", 569, 69],
	["/md5.c", 475, 49],
	["/menu.c", 1082, 273],
	["/mh.c", 2351, 757],
	["/mutt_idna.c", 343, 131],
	["/mutt_socket.c", 584, 168],
	["/mutt_ssl.c", 1125, 377],
	["/mutt_tunnel.c", 194, 91],
	["/muttlib.c", 1960, 568],
	["/mx.c", 1691, 556],
	["/pager.c", 2817, 631],
	["/parse.c", 1648, 588],
	["/patchlist.c", 13, 29],
	["/pattern.c", 1546, 557],
	["/pgp.c", 1866, 722],
	["/pgpinvoke.c", 358, 112],
	["/pgpkey.c", 1045, 393],
	["/pgplib.c", 253, 71],
	["/pgpmicalg.c", 212, 102],
	["/pgppacket.c", 232, 75],
	["/pop.c", 931, 336],
	["/pop_auth.c", 418, 109],
	["/pop_lib.c", 597, 240],
	["/postpone.c", 751, 238],
	["/query.c", 543, 219],
	["/recvattach.c", 1274, 431],
	["/recvcmd.c", 950, 293],
	["/resize.c", 80, 47],
	["/rfc1524.c", 594, 203],
	["/rfc2047.c", 924, 303],
	["/rfc2231.c", 384, 136],
	["/rfc3676.c", 390, 140],
	["/rfc822.c", 919, 241],
	["/safe_asprintf.c", 96, 35],
	["/score.c", 196, 74],
	["/send.c", 1954, 664],
	["/sendlib.c", 2890, 1004],
	["/signal.c", 254, 85],
	["/smime.c", 2280, 802],
	["/smtp.c", 666, 206],
	["/sort.c", 343, 129],
	["/status.c", 309, 148],
	["/system.c", 142, 65],
	["/thread.c", 1431, 386],
	["/url.c", 325, 164],
]);
$viewer->cmp_dynamic_data();

$exp->hard_close();

open( my $fh, ">", "check.good" );
print $fh <<EOF;
Checking ....done

Summary:
         3 Log files found
       218 Source files input
       262 Calls to the instrumentation tool
       218 Forked compilers
       209 Instrument successes
         9 Both instrument and native compile failed (FP)
        73 Application link commands
       339 Warnings during source parsing
        10 Errors during source parsing

Totals:
     94664 Lines of source code
      6976 Lines of instrumentation header
       102 Functions called 'main'
      1711 Function definitions
      4895 If statements
       484 For loops
       326 While loops
        37 Do while loops
       104 Switch statements
      1956 Return statement values
      6894 Call expressions
    153793 Total statements
     12082 Binary operators
       558 Errors rewriting source
EOF

system("$ENV{CITRUN_TOOLS}/citrun-check /usr/ports/pobj/mutt-* > check.out");
system("diff -u check.good check.out");

$package->clean();
