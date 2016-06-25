use strict;
use warnings;

use Cwd;
use Expect;
use File::Temp qw( tempdir );
use File::Which;
use List::MoreUtils qw ( each_array );
use Test::More tests => 2491;
use Time::HiRes qw( time );

use Test::Package;
use Test::Viewer;


# Download: LibreSSL 2.4.1 from ftp.openbsd.org.
my $libressl_url = "http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/";
my $package = Test::Package->new("libressl-2.4.1.tar.gz", $libressl_url, "tar xzf");

# Dependencies.
$package->dependencies("citrun");

my $srcdir = $package->dir() . "/libressl-2.4.1";

# Configure.
system("cd $srcdir && citrun-wrap ./configure") == 0 or die "citrun-wrap ./configure failed";

# Compile.
system("citrun-wrap make -C $srcdir -j8") == 0 or die "citrun-wrap make failed";

# Verify: 'openssl' binary has working instrumentation.
$ENV{CITRUN_SOCKET} = getcwd . "/citrun-test.socket";

my $exp = Expect->spawn("$srcdir/apps/openssl/openssl");

my $viewer = Test::Viewer->new();
$viewer->accept();

my $runtime_metadata = $viewer->get_metadata();
cmp_ok( $runtime_metadata->{num_tus}, ">", 615,	"tu count lower bound" );
cmp_ok( $runtime_metadata->{num_tus}, "<", 629,	"tu count upper bound" );

cmp_ok( $runtime_metadata->{pid}, ">", 1,	"pid lower bound check" );
cmp_ok( $runtime_metadata->{pid}, "<", 100000,	"pid upper bound check" );
cmp_ok( $runtime_metadata->{ppid}, ">", 1,	"ppid lower bound check" );
cmp_ok( $runtime_metadata->{ppid}, "<", 100000,	"ppid upper bound check" );
cmp_ok( $runtime_metadata->{pgrp}, ">", 1,	"pgrp lower bound check" );
cmp_ok( $runtime_metadata->{pgrp}, "<", 100000,	"pgrp upper bound check" );

#print STDERR "[ \"$_->{filename}\",$_->{lines},$_->{inst_sites} ],\n" for (@sorted_tus);
my @known_good = (
	# file name			lines	instrumented sites
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
	[ "crypto/aes/aes_cfb.c",	85,3 ],
	[ "crypto/aes/aes_ctr.c",	63,1 ],
	[ "crypto/aes/aes_ecb.c",	70,7 ],
	[ "crypto/aes/aes_ige.c",	195,31 ],
	[ "crypto/aes/aes_misc.c",	66,6 ],
	[ "crypto/aes/aes_ofb.c",	62,1 ],
	[ "crypto/aes/aes_wrap.c",	134,36 ],
	[ "crypto/asn1/a_bitstr.c",	260,60 ],
	[ "crypto/asn1/a_bool.c",	116,17 ],
	[ "crypto/asn1/a_bytes.c",	307,80 ],
	[ "crypto/asn1/a_d2i_fp.c",	297,66 ],
	[ "crypto/asn1/a_digest.c",	85,13 ],
	[ "crypto/asn1/a_dup.c",	119,23 ],
	[ "crypto/asn1/a_enum.c",	190,45 ],
	[ "crypto/asn1/a_i2d_fp.c",	159,37 ],
	[ "crypto/asn1/a_int.c",	462,111 ],
	[ "crypto/asn1/a_mbstr.c",	454,120 ],
	[ "crypto/asn1/a_object.c",	411,123 ],
	[ "crypto/asn1/a_octet.c",	80,11 ],
	[ "crypto/asn1/a_print.c",	126,27 ],
	[ "crypto/asn1/a_set.c",	238,54 ],
	[ "crypto/asn1/a_sign.c",	242,48 ],
	[ "crypto/asn1/a_strex.c",	647,224 ],
	[ "crypto/asn1/a_strnid.c",	293,78 ],
	[ "crypto/asn1/a_time.c",	108,12 ],
	[ "crypto/asn1/a_time_tm.c",	447,200 ],
	[ "crypto/asn1/a_type.c",	157,29 ],
	[ "crypto/asn1/a_utf8.c",	200,59 ],
	[ "crypto/asn1/a_verify.c",	174,31 ],
	[ "crypto/asn1/ameth_lib.c",	458,78 ],
	[ "crypto/asn1/asn1_err.c",	334,9 ],
	[ "crypto/asn1/asn1_gen.c",	812,188 ],
	[ "crypto/asn1/asn1_lib.c",	491,126 ],
	[ "crypto/asn1/asn1_par.c",	398,149 ],
	[ "crypto/asn1/asn_mime.c",	1020,350 ],
	[ "crypto/asn1/asn_moid.c",	159,60 ],
	[ "crypto/asn1/asn_pack.c",	216,46 ],
	[ "crypto/asn1/bio_asn1.c",	497,111 ],
	[ "crypto/asn1/bio_ndef.c",	244,47 ],
	[ "crypto/asn1/d2i_pr.c",	171,35 ],
	[ "crypto/asn1/d2i_pu.c",	137,24 ],
	[ "crypto/asn1/evp_asn1.c",	202,58 ],
	[ "crypto/asn1/f_enum.c",	202,43 ],
	[ "crypto/asn1/f_int.c",	205,45 ],
	[ "crypto/asn1/f_string.c",	198,42 ],
	[ "crypto/asn1/i2d_pr.c",	82,14 ],
	[ "crypto/asn1/i2d_pu.c",	99,13 ],
	[ "crypto/asn1/n_pkey.c",	435,117 ],
	[ "crypto/asn1/nsseq.c",	130,15 ],
	[ "crypto/asn1/p5_pbe.c",	187,41 ],
	[ "crypto/asn1/p5_pbev2.c",	375,96 ],
	[ "crypto/asn1/p8_pkey.c",	202,39 ],
	[ "crypto/asn1/t_bitst.c",	113,28 ],
	[ "crypto/asn1/t_crl.c",	141,41 ],
	[ "crypto/asn1/t_pkey.c",	115,35 ],
	[ "crypto/asn1/t_req.c",	268,95 ],
	[ "crypto/asn1/t_spki.c",	113,25 ],
	[ "crypto/asn1/t_x509.c",	538,222 ],
	[ "crypto/asn1/t_x509a.c",	119,33 ],
	[ "crypto/asn1/tasn_dec.c",	1189,301 ],
	[ "crypto/asn1/tasn_enc.c",	653,188 ],
	[ "crypto/asn1/tasn_fre.c",	244,60 ],
	[ "crypto/asn1/tasn_new.c",	375,94 ],
	[ "crypto/asn1/tasn_prn.c",	597,225 ],
	[ "crypto/asn1/tasn_typ.c",	800,146 ],
	[ "crypto/asn1/tasn_utl.c",	282,54 ],
	[ "crypto/asn1/x_algor.c",	223,48 ],
	[ "crypto/asn1/x_attrib.c",	199,29 ],
	[ "crypto/asn1/x_bignum.c",	168,28 ],
	[ "crypto/asn1/x_crl.c",	688,151 ],
	[ "crypto/asn1/x_exten.c",	154,18 ],
	[ "crypto/asn1/x_info.c",	108,18 ],
	[ "crypto/asn1/x_long.c",	211,29 ],
	[ "crypto/asn1/x_name.c",	643,159 ],
	[ "crypto/asn1/x_nx509.c",	114,12 ],
	[ "crypto/asn1/x_pkey.c",	122,25 ],
	[ "crypto/asn1/x_pubkey.c",	431,125 ],
	[ "crypto/asn1/x_req.c",	228,25 ],
	[ "crypto/asn1/x_sig.c",	111,12 ],
	[ "crypto/asn1/x_spki.c",	175,19 ],
	[ "crypto/asn1/x_val.c",	111,12 ],
	[ "crypto/asn1/x_x509.c",	347,54 ],
	[ "crypto/asn1/x_x509a.c",	326,77 ],
	[ "crypto/bf/bf_cfb64.c",	122,7 ],
	[ "crypto/bf/bf_ecb.c",		95,4 ],
	[ "crypto/bf/bf_enc.c",		307,9 ],
	[ "crypto/bf/bf_ofb64.c",	111,4 ],
	[ "crypto/bf/bf_skey.c",	118,16 ],
	[ "crypto/bio/b_dump.c",	183,47 ],
	[ "crypto/bio/b_posix.c",	89,14 ],
	[ "crypto/bio/b_print.c",	110,20 ],
	[ "crypto/bio/b_sock.c",	445,130 ],
	[ "crypto/bio/bf_buff.c",	521,152 ],
	[ "crypto/bio/bf_nbio.c",	253,57 ],
	[ "crypto/bio/bf_null.c",	197,44 ],
	[ "crypto/bio/bio_cb.c",	146,28 ],
	[ "crypto/bio/bio_err.c",	157,9 ],
	[ "crypto/bio/bio_lib.c",	625,180 ],
	[ "crypto/bio/bss_acpt.c",	454,108 ],
	[ "crypto/bio/bss_bio.c",	884,152 ],
	[ "crypto/bio/bss_conn.c",	605,134 ],
	[ "crypto/bio/bss_dgram.c",	659,114 ],
	[ "crypto/bio/bss_fd.c",	268,51 ],
	[ "crypto/bio/bss_file.c",	321,64 ],
	[ "crypto/bio/bss_log.c",	214,31 ],
	[ "crypto/bio/bss_mem.c",	322,55 ],
	[ "crypto/bio/bss_null.c",	159,19 ],
	[ "crypto/bio/bss_sock.c",	240,45 ],
	[ "crypto/bn/bn_add.c",		314,62 ],
	[ "crypto/bn/bn_asm.c",		1099,44 ],
	[ "crypto/bn/bn_blind.c",	389,93 ],
	[ "crypto/bn/bn_const.c",	410,21 ],
	[ "crypto/bn/bn_ctx.c",		479,60 ],
	[ "crypto/bn/bn_depr.c",	116,17 ],
	[ "crypto/bn/bn_div.c",		382,57 ],
	[ "crypto/bn/bn_err.c",		153,9 ],
	[ "crypto/bn/bn_exp.c",		1098,319 ],
	[ "crypto/bn/bn_exp2.c",309,80 ],
	[ "crypto/bn/bn_gcd.c",689,210 ],
	[ "crypto/bn/bn_gf2m.c",1324,253 ],
	[ "crypto/bn/bn_kron.c",186,35 ],
	[ "crypto/bn/bn_lib.c",896,187 ],
	[ "crypto/bn/bn_mod.c",306,97 ],
	[ "crypto/bn/bn_mont.c",539,96 ],
	[ "crypto/bn/bn_mpi.c",133,31 ],
	[ "crypto/bn/bn_mul.c",1172,252 ],
	[ "crypto/bn/bn_nist.c",1271,118 ],
	[ "crypto/bn/bn_prime.c",533,191 ],
	[ "crypto/bn/bn_print.c",408,129 ],
	[ "crypto/bn/bn_rand.c",292,68 ],
	[ "crypto/bn/bn_recp.c",264,83 ],
	[ "crypto/bn/bn_shift.c",219,35 ],
	[ "crypto/bn/bn_sqr.c",287,54 ],
	[ "crypto/bn/bn_sqrt.c",406,135 ],
	[ "crypto/bn/bn_word.c",234,53 ],
	[ "crypto/bn/bn_x931p.c",280,101 ],
	[ "crypto/buffer/buf_err.c",100,9 ],
	[ "crypto/buffer/buf_str.c",80,22 ],
	[ "crypto/buffer/buffer.c",195,44 ],
	[ "crypto/camellia/cmll_cfb.c",145,3 ],
	[ "crypto/camellia/cmll_ctr.c",64,1 ],
	[ "crypto/camellia/cmll_ecb.c",64,2 ],
	[ "crypto/camellia/cmll_misc.c",82,13 ],
	[ "crypto/camellia/cmll_ofb.c",123,1 ],
	[ "crypto/cast/c_cfb64.c",122,7 ],
	[ "crypto/cast/c_ecb.c",78,3 ],
	[ "crypto/cast/c_enc.c",211,11 ],
	[ "crypto/cast/c_ofb64.c",111,4 ],
	[ "crypto/cast/c_skey.c",167,11 ],
	[ "crypto/chacha/chacha.c",78,20 ],
	[ "crypto/cmac/cm_ameth.c",90,6 ],
	[ "crypto/cmac/cm_pmeth.c",214,74 ],
	[ "crypto/cmac/cmac.c",282,104 ],
	[ "crypto/comp/c_rle.c",56,15 ],
	[ "crypto/comp/c_zlib.c",565,6 ],
	[ "crypto/comp/comp_err.c",96,9 ],
	[ "crypto/comp/comp_lib.c",69,26 ],
	[ "crypto/conf/conf_api.c",280,69 ],
	[ "crypto/conf/conf_def.c",703,161 ],
	[ "crypto/conf/conf_err.c",132,9 ],
	[ "crypto/conf/conf_lib.c",376,103 ],
	[ "crypto/conf/conf_mall.c",83,7 ],
	[ "crypto/conf/conf_mod.c",600,169 ],
	[ "crypto/conf/conf_sap.c",114,18 ],
	[ "crypto/cpt_err.c",106,9 ],
	[ "crypto/cryptlib.c",717,96 ],
	[ "crypto/cversion.c",87,12 ],
	[ "crypto/des/cbc_cksm.c",107,11 ],
	[ "crypto/des/cbc_enc.c",62,15 ],
	[ "crypto/des/cfb64ede.c",245,29 ],
	[ "crypto/des/cfb64enc.c",122,13 ],
	[ "crypto/des/cfb_enc.c",190,22 ],
	[ "crypto/des/des_enc.c",405,40 ],
	[ "crypto/des/ecb3_enc.c",84,9 ],
	[ "crypto/des/ecb_enc.c",119,11 ],
	[ "crypto/des/ede_cbcm_enc.c",200,19 ],
	[ "crypto/des/enc_read.c",230,50 ],
	[ "crypto/des/enc_writ.c",174,28 ],
	[ "crypto/des/fcrypt.c",126,18 ],
	[ "crypto/des/fcrypt_b.c",147,9 ],
	[ "crypto/des/ofb64ede.c",115,10 ],
	[ "crypto/des/ofb64enc.c",111,10 ],
	[ "crypto/des/ofb_enc.c",136,15 ],
	[ "crypto/des/pcbc_enc.c",124,13 ],
	[ "crypto/des/qud_cksm.c",126,12 ],
	[ "crypto/des/rand_key.c",69,5 ],
	[ "crypto/des/set_key.c",401,35 ],
	[ "crypto/des/str2key.c",175,33 ],
	[ "crypto/des/xcbc_enc.c",149,15 ],
	[ "crypto/dh/dh_ameth.c",494,146 ],
	[ "crypto/dh/dh_asn1.c",144,20 ],
	[ "crypto/dh/dh_check.c",136,34 ],
	[ "crypto/dh/dh_depr.c",84,11 ],
	[ "crypto/dh/dh_err.c",126,9 ],
	[ "crypto/dh/dh_gen.c",180,47 ],
	[ "crypto/dh/dh_key.c",266,68 ],
	[ "crypto/dh/dh_lib.c",242,61 ],
	[ "crypto/dh/dh_pmeth.c",265,57 ],
	[ "crypto/dh/dh_prn.c",80,12 ],
	[ "crypto/dsa/dsa_ameth.c",699,219 ],
	[ "crypto/dsa/dsa_asn1.c",440,58 ],
	[ "crypto/dsa/dsa_depr.c",93,11 ],
	[ "crypto/dsa/dsa_err.c",134,9 ],
	[ "crypto/dsa/dsa_gen.c",358,138 ],
	[ "crypto/dsa/dsa_key.c",134,30 ],
	[ "crypto/dsa/dsa_lib.c",306,85 ],
	[ "crypto/dsa/dsa_ossl.c",424,115 ],
	[ "crypto/dsa/dsa_pmeth.c",338,79 ],
	[ "crypto/dsa/dsa_prn.c",124,33 ],
	[ "crypto/dsa/dsa_sign.c",98,16 ],
	[ "crypto/dsa/dsa_vrf.c",68,7 ],
	[ "crypto/dso/dso_dlfcn.c",356,5 ],
	[ "crypto/dso/dso_err.c",160,9 ],
	[ "crypto/dso/dso_lib.c",455,137 ],
	[ "crypto/dso/dso_null.c",75,6 ],
	[ "crypto/dso/dso_openssl.c",76,7 ],
	[ "crypto/ec/ec2_mult.c",451,186 ],
	[ "crypto/ec/ec2_oct.c",383,135 ],
	[ "crypto/ec/ec2_smpl.c",788,312 ],
	[ "crypto/ec/ec_ameth.c",637,232 ],
	[ "crypto/ec/ec_asn1.c",1619,389 ],
	[ "crypto/ec/ec_check.c",116,29 ],
	[ "crypto/ec/ec_curve.c",3341,65 ],
	[ "crypto/ec/ec_cvt.c",168,29 ],
	[ "crypto/ec/ec_err.c",280,9 ],
	[ "crypto/ec/ec_key.c",541,169 ],
	[ "crypto/ec/ec_lib.c",1121,395 ],
	[ "crypto/ec/ec_mult.c",887,218 ],
	[ "crypto/ec/ec_oct.c",193,53 ],
	[ "crypto/ec/ec_pmeth.c",324,93 ],
	[ "crypto/ec/ec_print.c",179,50 ],
	[ "crypto/ec/eck_prn.c",372,161 ],
	[ "crypto/ec/ecp_mont.c",295,73 ],
	[ "crypto/ec/ecp_nist.c",213,54 ],
	[ "crypto/ec/ecp_oct.c",396,149 ],
	[ "crypto/ec/ecp_smpl.c",1411,650 ],
	[ "crypto/ecdh/ech_err.c",102,9 ],
	[ "crypto/ecdh/ech_key.c",227,54 ],
	[ "crypto/ecdh/ech_lib.c",248,59 ],
	[ "crypto/ecdsa/ecs_asn1.c",116,12 ],
	[ "crypto/ecdsa/ecs_err.c",107,9 ],
	[ "crypto/ecdsa/ecs_lib.c",265,73 ],
	[ "crypto/ecdsa/ecs_ossl.c",431,142 ],
	[ "crypto/ecdsa/ecs_sign.c",112,24 ],
	[ "crypto/ecdsa/ecs_vrf.c",117,24 ],
	[ "crypto/engine/eng_all.c",79,7 ],
	[ "crypto/engine/eng_cnf.c",258,79 ],
	[ "crypto/engine/eng_ctrl.c",394,136 ],
	[ "crypto/engine/eng_dyn.c",65,5 ],
	[ "crypto/engine/eng_err.c",174,9 ],
	[ "crypto/engine/eng_fat.c",193,84 ],
	[ "crypto/engine/eng_init.c",151,29 ],
	[ "crypto/engine/eng_lib.c",368,72 ],
	[ "crypto/engine/eng_list.c",397,70 ],
	[ "crypto/engine/eng_openssl.c",407,67 ],
	[ "crypto/engine/eng_pkey.c",196,39 ],
	[ "crypto/engine/eng_table.c",356,62 ],
	[ "crypto/engine/tb_asnmth.c",257,56 ],
	[ "crypto/engine/tb_cipher.c",154,31 ],
	[ "crypto/engine/tb_dh.c",128,23 ],
	[ "crypto/engine/tb_digest.c",154,31 ],
	[ "crypto/engine/tb_dsa.c",128,23 ],
	[ "crypto/engine/tb_ecdh.c",142,23 ],
	[ "crypto/engine/tb_ecdsa.c",128,23 ],
	[ "crypto/engine/tb_pkmeth.c",177,37 ],
	[ "crypto/engine/tb_rand.c",128,23 ],
	[ "crypto/engine/tb_rsa.c",128,23 ],
	[ "crypto/engine/tb_store.c",110,17 ],
	[ "crypto/err/err.c",1157,189 ],
	[ "crypto/err/err_all.c",162,32 ],
	[ "crypto/err/err_prn.c",118,22 ],
	[ "crypto/evp/bio_b64.c",568,116 ],
	[ "crypto/evp/bio_enc.c",428,89 ],
	[ "crypto/evp/bio_md.c",278,65 ],
	[ "crypto/evp/c_all.c",299,205 ],
	[ "crypto/evp/digest.c",406,117 ],
	[ "crypto/evp/e_aes.c",1549,382 ],
	[ "crypto/evp/e_aes_cbc_hmac_sha1.c",605,101 ],
	[ "crypto/evp/e_bf.c",92,8 ],
	[ "crypto/evp/e_camellia.c",125,9 ],
	[ "crypto/evp/e_cast.c",93,8 ],
	[ "crypto/evp/e_chacha.c",70,13 ],
	[ "crypto/evp/e_chacha20poly1305.c",325,82 ],
	[ "crypto/evp/e_des.c",227,41 ],
	[ "crypto/evp/e_des3.c",285,52 ],
	[ "crypto/evp/e_gost2814789.c",230,66 ],
	[ "crypto/evp/e_idea.c",126,14 ],
	[ "crypto/evp/e_null.c",106,10 ],
	[ "crypto/evp/e_old.c",160,25 ],
	[ "crypto/evp/e_rc2.c",255,54 ],
	[ "crypto/evp/e_rc4.c",141,12 ],
	[ "crypto/evp/e_rc4_hmac_md5.c",310,51 ],
	[ "crypto/evp/e_xcbc_d.c",138,15 ],
	[ "crypto/evp/encode.c",424,60 ],
	[ "crypto/evp/evp_aead.c",145,35 ],
	[ "crypto/evp/evp_enc.c",671,219 ],
	[ "crypto/evp/evp_err.c",262,9 ],
	[ "crypto/evp/evp_key.c",207,65 ],
	[ "crypto/evp/evp_lib.c",349,62 ],
	[ "crypto/evp/evp_pbe.c",296,60 ],
	[ "crypto/evp/evp_pkey.c",241,58 ],
	[ "crypto/evp/m_dss.c",118,12 ],
	[ "crypto/evp/m_dss1.c",118,12 ],
	[ "crypto/evp/m_ecdsa.c",167,12 ],
	[ "crypto/evp/m_gost2814789.c",111,18 ],
	[ "crypto/evp/m_gostr341194.c",98,12 ],
	[ "crypto/evp/m_md4.c",119,12 ],
	[ "crypto/evp/m_md5.c",119,12 ],
	[ "crypto/evp/m_null.c",107,9 ],
	[ "crypto/evp/m_ripemd.c",119,12 ],
	[ "crypto/evp/m_sha1.c",282,32 ],
	[ "crypto/evp/m_sigver.c",194,76 ],
	[ "crypto/evp/m_streebog.c",132,19 ],
	[ "crypto/evp/m_wp.c",57,12 ],
	[ "crypto/evp/names.c",229,56 ],
	[ "crypto/evp/p5_crpt.c",159,51 ],
	[ "crypto/evp/p5_crpt2.c",309,88 ],
	[ "crypto/evp/p_dec.c",93,8 ],
	[ "crypto/evp/p_enc.c",90,8 ],
	[ "crypto/evp/p_lib.c",484,141 ],
	[ "crypto/evp/p_open.c",129,29 ],
	[ "crypto/evp/p_seal.c",125,32 ],
	[ "crypto/evp/p_sign.c",124,30 ],
	[ "crypto/evp/p_verify.c",120,28 ],
	[ "crypto/evp/pmeth_fn.c",363,105 ],
	[ "crypto/evp/pmeth_gn.c",228,61 ],
	[ "crypto/evp/pmeth_lib.c",619,94 ],
	[ "crypto/ex_data.c",639,94 ],
	[ "crypto/gost/gost2814789.c",472,175 ],
	[ "crypto/gost/gost89_keywrap.c",139,33 ],
	[ "crypto/gost/gost89_params.c",245,20 ],
	[ "crypto/gost/gost89imit_ameth.c",89,9 ],
	[ "crypto/gost/gost89imit_pmeth.c",253,70 ],
	[ "crypto/gost/gost_asn1.c",296,40 ],
	[ "crypto/gost/gost_err.c",143,9 ],
	[ "crypto/gost/gostr341001.c",402,174 ],
	[ "crypto/gost/gostr341001_ameth.c",738,332 ],
	[ "crypto/gost/gostr341001_key.c",323,99 ],
	[ "crypto/gost/gostr341001_params.c",133,16 ],
	[ "crypto/gost/gostr341001_pmeth.c",720,286 ],
	[ "crypto/gost/gostr341194.c",274,85 ],
	[ "crypto/gost/streebog.c",1478,79 ],
	[ "crypto/hmac/hm_ameth.c",170,29 ],
	[ "crypto/hmac/hm_pmeth.c",260,76 ],
	[ "crypto/hmac/hmac.c",226,82 ],
	[ "crypto/idea/i_cbc.c",169,9 ],
	[ "crypto/idea/i_cfb64.c",123,7 ],
	[ "crypto/idea/i_ecb.c",84,4 ],
	[ "crypto/idea/i_ofb64.c",112,4 ],
	[ "crypto/idea/i_skey.c",158,15 ],
	[ "crypto/krb5/krb5_asn.c",723,82 ],
	[ "crypto/lhash/lh_stats.c",255,46 ],
	[ "crypto/lhash/lhash.c",464,69 ],
	[ "crypto/malloc-wrapper.c",198,50 ],
	[ "crypto/md4/md4_dgst.c",168,27 ],
	[ "crypto/md4/md4_one.c",78,12 ],
	[ "crypto/md5/md5_dgst.c",184,26 ],
	[ "crypto/md5/md5_one.c",78,12 ],
	[ "crypto/mem_clr.c",12,6 ],
	[ "crypto/mem_dbg.c",202,14 ],
	[ "crypto/modes/cbc128.c",203,38 ],
	[ "crypto/modes/ccm128.c",442,92 ],
	[ "crypto/modes/cfb128.c",235,41 ],
	[ "crypto/modes/ctr128.c",253,36 ],
	[ "crypto/modes/cts128.c",268,91 ],
	[ "crypto/modes/gcm128.c",1540,123 ],
	[ "crypto/modes/ofb128.c",120,16 ],
	[ "crypto/modes/xts128.c",188,24 ],
	[ "crypto/o_init.c",11,5 ],
	[ "crypto/o_str.c",22,5 ],
	[ "crypto/o_time.c",162,11 ],
	[ "crypto/objects/o_names.c",355,75 ],
	[ "crypto/objects/obj_dat.c",787,262 ],
	[ "crypto/objects/obj_err.c",103,9 ],
	[ "crypto/objects/obj_lib.c",131,32 ],
	[ "crypto/objects/obj_xref.c",206,45 ],
	[ "crypto/ocsp/ocsp_asn.c",963,110 ],
	[ "crypto/ocsp/ocsp_cl.c",384,103 ],
	[ "crypto/ocsp/ocsp_err.c",143,9 ],
	[ "crypto/ocsp/ocsp_ext.c",608,174 ],
	[ "crypto/ocsp/ocsp_ht.c",464,158 ],
	[ "crypto/ocsp/ocsp_lib.c",283,82 ],
	[ "crypto/ocsp/ocsp_prn.c",313,127 ],
	[ "crypto/ocsp/ocsp_srv.c",277,84 ],
	[ "crypto/ocsp/ocsp_vfy.c",449,137 ],
	[ "crypto/pem/pem_all.c",314,44 ],
	[ "crypto/pem/pem_err.c",162,9 ],
	[ "crypto/pem/pem_info.c",407,121 ],
	[ "crypto/pem/pem_lib.c",873,363 ],
	[ "crypto/pem/pem_oth.c",88,11 ],
	[ "crypto/pem/pem_pk8.c",257,73 ],
	[ "crypto/pem/pem_pkey.c",254,81 ],
	[ "crypto/pem/pem_seal.c",191,44 ],
	[ "crypto/pem/pem_sign.c",106,15 ],
	[ "crypto/pem/pem_x509.c",68,5 ],
	[ "crypto/pem/pem_xaux.c",70,5 ],
	[ "crypto/pem/pvkfmt.c",940,338 ],
	[ "crypto/pkcs12/p12_add.c",267,66 ],
	[ "crypto/pkcs12/p12_asn.c",477,33 ],
	[ "crypto/pkcs12/p12_attr.c",156,33 ],
	[ "crypto/pkcs12/p12_crpt.c",119,25 ],
	[ "crypto/pkcs12/p12_crt.c",351,113 ],
	[ "crypto/pkcs12/p12_decr.c",191,41 ],
	[ "crypto/pkcs12/p12_init.c",98,15 ],
	[ "crypto/pkcs12/p12_key.c",200,74 ],
	[ "crypto/pkcs12/p12_kiss.c",298,97 ],
	[ "crypto/pkcs12/p12_mutl.c",211,68 ],
	[ "crypto/pkcs12/p12_npas.c",245,75 ],
	[ "crypto/pkcs12/p12_p8d.c",69,7 ],
	[ "crypto/pkcs12/p12_p8e.c",101,17 ],
	[ "crypto/pkcs12/p12_utl.c",169,34 ],
	[ "crypto/pkcs12/pk12err.c",145,9 ],
	[ "crypto/pkcs7/bio_pk7.c",67,7 ],
	[ "crypto/pkcs7/pk7_asn1.c",969,98 ],
	[ "crypto/pkcs7/pk7_attr.c",175,52 ],
	[ "crypto/pkcs7/pk7_doit.c",1288,411 ],
	[ "crypto/pkcs7/pk7_lib.c",669,207 ],
	[ "crypto/pkcs7/pk7_mime.c",99,37 ],
	[ "crypto/pkcs7/pk7_smime.c",601,205 ],
	[ "crypto/pkcs7/pkcs7err.c",188,9 ],
	[ "crypto/poly1305/poly1305.c",39,35 ],
	[ "crypto/rand/rand_err.c",102,9 ],
	[ "crypto/rand/rand_lib.c",101,11 ],
	[ "crypto/rand/randfile.c",144,29 ],
	[ "crypto/rc2/rc2_cbc.c",227,13 ],
	[ "crypto/rc2/rc2_ecb.c",87,3 ],
	[ "crypto/rc2/rc2_skey.c",139,12 ],
	[ "crypto/rc2/rc2cfb64.c",123,7 ],
	[ "crypto/rc2/rc2ofb64.c",112,4 ],
	[ "crypto/ripemd/rmd_dgst.c",291,27 ],
	[ "crypto/ripemd/rmd_one.c",79,12 ],
	[ "crypto/rsa/rsa_ameth.c",676,264 ],
	[ "crypto/rsa/rsa_asn1.c",309,33 ],
	[ "crypto/rsa/rsa_chk.c",214,63 ],
	[ "crypto/rsa/rsa_crpt.c",218,58 ],
	[ "crypto/rsa/rsa_depr.c",102,19 ],
	[ "crypto/rsa/rsa_eay.c",914,270 ],
	[ "crypto/rsa/rsa_err.c",211,9 ],
	[ "crypto/rsa/rsa_gen.c",241,88 ],
	[ "crypto/rsa/rsa_lib.c",259,68 ],
	[ "crypto/rsa/rsa_none.c",99,16 ],
	[ "crypto/rsa/rsa_oaep.c",237,78 ],
	[ "crypto/rsa/rsa_pk1.c",225,44 ],
	[ "crypto/rsa/rsa_pmeth.c",617,228 ],
	[ "crypto/rsa/rsa_prn.c",94,19 ],
	[ "crypto/rsa/rsa_pss.c",290,77 ],
	[ "crypto/rsa/rsa_saos.c",150,34 ],
	[ "crypto/rsa/rsa_sign.c",256,71 ],
	[ "crypto/rsa/rsa_ssl.c",152,30 ],
	[ "crypto/rsa/rsa_x931.c",168,31 ],
	[ "crypto/sha/sha1_one.c",82,12 ],
	[ "crypto/sha/sha1dgst.c",73,26 ],
	[ "crypto/sha/sha256.c",285,44 ],
	[ "crypto/sha/sha512.c",559,51 ],
	[ "crypto/stack/stack.c",342,101 ],
	[ "crypto/ts/ts_asn1.c",896,113 ],
	[ "crypto/ts/ts_conf.c",533,169 ],
	[ "crypto/ts/ts_err.c",180,9 ],
	[ "crypto/ts/ts_lib.c",151,46 ],
	[ "crypto/ts/ts_req_print.c",105,27 ],
	[ "crypto/ts/ts_req_utils.c",256,64 ],
	[ "crypto/ts/ts_rsp_print.c",302,102 ],
	[ "crypto/ts/ts_rsp_sign.c",1023,334 ],
	[ "crypto/ts/ts_rsp_utils.c",437,123 ],
	[ "crypto/ts/ts_rsp_verify.c",746,192 ],
	[ "crypto/ts/ts_verify_ctx.c",167,47 ],
	[ "crypto/txt_db/txt_db.c",373,108 ],
	[ "crypto/ui/ui_err.c",113,9 ],
	[ "crypto/ui/ui_lib.c",886,248 ],
	[ "crypto/ui/ui_openssl.c",398,115 ],
	[ "crypto/ui/ui_util.c",112,24 ],
	[ "crypto/whrlpool/wp_dgst.c",267,54 ],
	[ "crypto/x509/by_dir.c",423,94 ],
	[ "crypto/x509/by_file.c",275,72 ],
	[ "crypto/x509/by_mem.c",139,23 ],
	[ "crypto/x509/x509_att.c",404,139 ],
	[ "crypto/x509/x509_cmp.c",370,125 ],
	[ "crypto/x509/x509_d2.c",129,36 ],
	[ "crypto/x509/x509_def.c",99,11 ],
	[ "crypto/x509/x509_err.c",165,9 ],
	[ "crypto/x509/x509_ext.c",233,59 ],
	[ "crypto/x509/x509_lu.c",740,207 ],
	[ "crypto/x509/x509_obj.c",180,43 ],
	[ "crypto/x509/x509_r2x.c",116,29 ],
	[ "crypto/x509/x509_req.c",348,95 ],
	[ "crypto/x509/x509_set.c",155,46 ],
	[ "crypto/x509/x509_trs.c",333,79 ],
	[ "crypto/x509/x509_txt.c",190,62 ],
	[ "crypto/x509/x509_v3.c",301,93 ],
	[ "crypto/x509/x509_vfy.c",2158,634 ],
	[ "crypto/x509/x509_vpm.c",450,81 ],
	[ "crypto/x509/x509cset.c",174,47 ],
	[ "crypto/x509/x509name.c",411,134 ],
	[ "crypto/x509/x509rset.c",89,17 ],
	[ "crypto/x509/x509spki.c",133,33 ],
	[ "crypto/x509/x509type.c",131,21 ],
	[ "crypto/x509/x_all.c",603,131 ],
	[ "crypto/x509v3/pcy_cache.c",272,69 ],
	[ "crypto/x509v3/pcy_data.c",130,21 ],
	[ "crypto/x509v3/pcy_lib.c",158,31 ],
	[ "crypto/x509v3/pcy_map.c",127,19 ],
	[ "crypto/x509v3/pcy_node.c",200,46 ],
	[ "crypto/x509v3/pcy_tree.c",769,205 ],
	[ "crypto/x509v3/v3_akey.c",216,53 ],
	[ "crypto/x509v3/v3_akeya.c",125,12 ],
	[ "crypto/x509v3/v3_alt.c",672,193 ],
	[ "crypto/x509v3/v3_bcons.c",186,28 ],
	[ "crypto/x509v3/v3_bitst.c",176,23 ],
	[ "crypto/x509v3/v3_conf.c",577,187 ],
	[ "crypto/x509v3/v3_cpols.c",776,169 ],
	[ "crypto/x509v3/v3_crld.c",817,219 ],
	[ "crypto/x509v3/v3_enum.c",108,12 ],
	[ "crypto/x509v3/v3_extku.c",206,23 ],
	[ "crypto/x509v3/v3_genn.c",475,71 ],
	[ "crypto/x509v3/v3_ia5.c",240,18 ],
	[ "crypto/x509v3/v3_info.c",308,53 ],
	[ "crypto/x509v3/v3_int.c",111,7 ],
	[ "crypto/x509v3/v3_lib.c",346,88 ],
	[ "crypto/x509v3/v3_ncons.c",561,135 ],
	[ "crypto/x509v3/v3_ocsp.c",381,82 ],
	[ "crypto/x509v3/v3_pci.c",333,94 ],
	[ "crypto/x509v3/v3_pcia.c",146,19 ],
	[ "crypto/x509v3/v3_pcons.c",184,25 ],
	[ "crypto/x509v3/v3_pku.c",167,22 ],
	[ "crypto/x509v3/v3_pmaps.c",219,26 ],
	[ "crypto/x509v3/v3_prn.c",226,86 ],
	[ "crypto/x509v3/v3_purp.c",862,262 ],
	[ "crypto/x509v3/v3_skey.c",161,31 ],
	[ "crypto/x509v3/v3_sxnet.c",387,84 ],
	[ "crypto/x509v3/v3_utl.c",926,328 ],
	[ "crypto/x509v3/v3err.c",227,9 ],
	[ "ssl/bio_ssl.c",582,151 ],
	[ "ssl/bs_ber.c",269,97 ],
	[ "ssl/bs_cbb.c",443,148 ],
	[ "ssl/bs_cbs.c",512,183 ],
	[ "ssl/d1_both.c",1375,307 ],
	[ "ssl/d1_clnt.c",725,145 ],
	[ "ssl/d1_enc.c",213,34 ],
	[ "ssl/d1_lib.c",469,132 ],
	[ "ssl/d1_meth.c",113,10 ],
	[ "ssl/d1_pkt.c",1478,322 ],
	[ "ssl/d1_srtp.c",474,87 ],
	[ "ssl/d1_srvr.c",752,132 ],
	[ "ssl/pqueue.c",202,31 ],
	[ "ssl/s23_clnt.c",481,83 ],
	[ "ssl/s23_lib.c",133,33 ],
	[ "ssl/s23_pkt.c",117,17 ],
	[ "ssl/s23_srvr.c",507,94 ],
	[ "ssl/s3_both.c",744,159 ],
	[ "ssl/s3_cbc.c",657,90 ],
	[ "ssl/s3_clnt.c",2636,639 ],
	[ "ssl/s3_lib.c",2860,224 ],
	[ "ssl/s3_pkt.c",1391,274 ],
	[ "ssl/s3_srvr.c",2693,593 ],
	[ "ssl/ssl_algs.c",132,67 ],
	[ "ssl/ssl_asn1.c",692,206 ],
	[ "ssl/ssl_cert.c",723,172 ],
	[ "ssl/ssl_ciph.c",1799,277 ],
	[ "ssl/ssl_err.c",616,9 ],
	[ "ssl/ssl_err2.c",73,7 ],
	[ "ssl/ssl_lib.c",3063,776 ],
	[ "ssl/ssl_rsa.c",752,220 ],
	[ "ssl/ssl_sess.c",1100,222 ],
	[ "ssl/ssl_stat.c",802,27 ],
	[ "ssl/ssl_txt.c",188,63 ],
	[ "ssl/t1_clnt.c",238,21 ],
	[ "ssl/t1_enc.c",1420,410 ],
	[ "ssl/t1_lib.c",2405,668 ],
	[ "ssl/t1_meth.c",236,21 ],
	[ "ssl/t1_reneg.c",287,52 ],
	[ "ssl/t1_srvr.c",239,21 ],
);

my $tus = $runtime_metadata->{tus};
my @sorted_tus = sort keys %$tus;

# Walk two lists at the same time
# http://stackoverflow.com/questions/822563/how-can-i-iterate-over-multiple-lists-at-the-same-time-in-perl
my $it = each_array( @known_good, @sorted_tus );
while ( my ($x, $key) = $it->() ) {
	my $y = $tus->{$key};

	like( $key,	qr/.*$x->[0]/,	"libressl $x->[0]: filename check" );
	is ( $y->{lines},	$x->[1],	"libressl $x->[0]: total lines check" );

	# Check instrumented sites as a range
	cmp_ok ( $y->{inst_sites}, ">", $x->[2] - 5, "libressl $x->[0]: instrumented sites check lower" );
	cmp_ok ( $y->{inst_sites}, "<", $x->[2] + 5, "libressl $x->[0]: instrumented sites check upper" );
}

$exp->hard_close();
