use strict;
use warnings;

use Cwd;
use File::Which;
use Expect;
use File::Temp qw( tempdir );
use IPC::Open2;
use List::MoreUtils qw ( each_array );
use SCV::Viewer;
use Test::More tests => 207;
use Time::HiRes qw( time );

#
# Build and test LibReSSL with citrun.
#

# Download source, extract, configure and compile
#
my $tmpdir = tempdir( CLEANUP => 1 );

my $libressl_src = "libressl-2.4.1.tar.gz";
my $libressl_url = "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/$libressl_src";

system("cd $tmpdir && curl -O $libressl_url") == 0 or die "download failed";
system("cd $tmpdir && tar xzf $libressl_src") == 0 or die "extract failed";

my $srcdir = "$tmpdir/libressl-2.4.1";
system("cd $srcdir && citrun-wrap ./configure") == 0 or die "citrun-wrap ./configure failed";

system("citrun-wrap make -C $srcdir -j8") == 0 or die "citrun-wrap make failed";

# Make sure the instrumentation for Vim is working correctly
#
my $viewer = SCV::Viewer->new();
$ENV{CITRUN_SOCKET} = getcwd . "/citrun-test.socket";

my $exp = Expect->spawn("$srcdir/apps/openssl/openssl");
$viewer->accept();

my $runtime_metadata = $viewer->get_metadata();
is( $runtime_metadata->{num_tus}, 50,		"libressl translation unit count" );
cmp_ok( $runtime_metadata->{pid}, ">", 1,	"libressl pid lower bound check" );
cmp_ok( $runtime_metadata->{pid}, "<", 100000,	"libressl pid upper bound check" );
cmp_ok( $runtime_metadata->{ppid}, ">", 1,	"libressl ppid lower bound check" );
cmp_ok( $runtime_metadata->{ppid}, "<", 100000,	"libressl ppid upper bound check" );
cmp_ok( $runtime_metadata->{pgrp}, ">", 1,	"libressl pgrp lower bound check" );
cmp_ok( $runtime_metadata->{pgrp}, "<", 100000,	"libressl pgrp upper bound check" );

my $tus = $runtime_metadata->{tus};
my @sorted_tus = sort { $a->{filename} cmp $b->{filename} } @$tus;

# Use this to regenerate:
#print STDERR "[ \"$_->{filename}\",\t$_->{lines},\t$_->{inst_sites} ],\n" for (@sorted_tus);
# [ File Name,	Total lines in file,	Number of instrumented sites ];
my @known_good = (
	[ "apps/openssl/apps.c",	2323,   918 ],
	[ "apps/openssl/apps_posix.c",	165,    18 ],
	[ "apps/openssl/asn1pars.c",	483,    124 ],
	[ "apps/openssl/ca.c",		2717,   1158 ],
	[ "apps/openssl/certhash.c",	689,    247 ],
	[ "apps/openssl/ciphers.c",	153,    47 ],
	[ "apps/openssl/cms.c",		1143,   5 ],
	[ "apps/openssl/crl.c",		478,    131 ],
	[ "apps/openssl/crl2p7.c",	334,    88 ],
	[ "apps/openssl/dgst.c",	545,    252 ],
	[ "apps/openssl/dh.c",		301,    89 ],
	[ "apps/openssl/dhparam.c",	500,    140 ],
	[ "apps/openssl/dsa.c",		374,    112 ],
	[ "apps/openssl/dsaparam.c",	372,    117 ],
	[ "apps/openssl/ec.c",		407,    126 ],
	[ "apps/openssl/ecparam.c",	616,    211 ],
	[ "apps/openssl/enc.c",		771,    243 ],
	[ "apps/openssl/errstr.c",	149,    29 ],
	[ "apps/openssl/gendh.c",	218,    44 ],
	[ "apps/openssl/gendsa.c",	217,    88 ],
	[ "apps/openssl/genpkey.c",	360,    162 ],
	[ "apps/openssl/genrsa.c",	267,    98 ],
	[ "apps/openssl/nseq.c",	177,    44 ],
	[ "apps/openssl/ocsp.c",	1221,   563 ],
	[ "apps/openssl/openssl.c",	837,    205 ],
	[ "apps/openssl/passwd.c",	492,    124 ],
	[ "apps/openssl/pkcs12.c",	897,    425 ],
	[ "apps/openssl/pkcs7.c",	290,    67 ],
	[ "apps/openssl/pkcs8.c",	420,    111 ],
	[ "apps/openssl/pkey.c",	221,    84 ],
	[ "apps/openssl/pkeyparam.c",	175,    37 ],
	[ "apps/openssl/pkeyutl.c",	495,    202 ],
	[ "apps/openssl/prime.c",	200,    51 ],
	[ "apps/openssl/rand.c",	186,    66 ],
	[ "apps/openssl/req.c",		1561,   760 ],
	[ "apps/openssl/rsa.c",		450,    109 ],
	[ "apps/openssl/rsautl.c",	333,    138 ],
	[ "apps/openssl/s_cb.c",	850,    166 ],
	[ "apps/openssl/s_client.c",	1491,   692 ],
	[ "apps/openssl/s_server.c",	2038,   948 ],
	[ "apps/openssl/s_socket.c",	339,    114 ],
	[ "apps/openssl/s_time.c",	553,    155 ],
	[ "apps/openssl/sess_id.c",	296,    69 ],
	[ "apps/openssl/smime.c",	683,    363 ],
	[ "apps/openssl/speed.c",	2159,   928 ],
	[ "apps/openssl/spkac.c",	314,    84 ],
	[ "apps/openssl/ts.c",		1091,   411 ],
	[ "apps/openssl/verify.c",	325,    126 ],
	[ "apps/openssl/version.c",	270,    50 ],
	[ "apps/openssl/x509.c",	1151,   592 ],
);

# Walk two lists at the same time
# http://stackoverflow.com/questions/822563/how-can-i-iterate-over-multiple-lists-at-the-same-time-in-perl
my $it = each_array( @known_good, @sorted_tus );
while ( my ($x, $y) = $it->() ) {
	like( $y->{filename},	qr/.*$x->[0]/,	"libressl $x->[0]: filename check" );
	is ( $y->{lines},	$x->[1],	"libressl $x->[0]: total lines check" );

	# Check instrumented sites as a range
	cmp_ok ( $y->{inst_sites}, ">", $x->[2] - 5, "libressl $x->[0]: instrumented sites check lower" );
	cmp_ok ( $y->{inst_sites}, "<", $x->[2] + 5, "libressl $x->[0]: instrumented sites check upper" );
}

$exp->hard_close();
