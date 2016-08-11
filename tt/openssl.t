use strict;
use warnings;
use Expect;
use Test::More tests => 1368 ;
use test::package;
use test::viewer;

my $package = test::package->new("security/openssl");
my $viewer = test::viewer->new();

$ENV{LD_LIBRARY_PATH}="/usr/ports/pobj/openssl-1.0.2h/openssl-1.0.2h";
my $exp = Expect->spawn("/usr/ports/pobj/openssl*/openssl*/apps/openssl");
$viewer->accept();
$viewer->cmp_static_data([
	["apps/app_rand.c", 218, 56],
	["apps/apps.c", 3229, 1018],
	["apps/asn1pars.c", 431, 189],
	["apps/ca.c", 2921, 1191],
	["apps/ciphers.c", 240, 74],
	["apps/cms.c", 1358, 703],
	["apps/crl.c", 443, 199],
	["apps/crl2p7.c", 335, 123],
	["apps/dgst.c", 615, 294],
	["apps/dh.c", 338, 139],
	["apps/dhparam.c", 547, 210],
	["apps/dsa.c", 375, 154],
	["apps/dsaparam.c", 470, 177],
	["apps/ec.c", 366, 163],
	["apps/ecparam.c", 662, 298],
	["apps/enc.c", 716, 339],
	["apps/engine.c", 513, 215],
	["apps/errstr.c", 122, 38],
	["apps/gendh.c", 249, 82],
	["apps/gendsa.c", 288, 128],
	["apps/genpkey.c", 406, 187],
	["apps/genrsa.c", 351, 139],
	["apps/nseq.c", 171, 66],
	["apps/ocsp.c", 1368, 606],
	["apps/openssl.c", 697, 195],
	["apps/passwd.c", 495, 170],
	["apps/pkcs12.c", 1059, 462],
	["apps/pkcs7.c", 313, 120],
	["apps/pkcs8.c", 403, 186],
	["apps/pkey.c", 252, 105],
	["apps/pkeyparam.c", 186, 70],
	["apps/pkeyutl.c", 556, 231],
	["apps/prime.c", 152, 66],
	["apps/rand.c", 230, 107],
	["apps/req.c", 1733, 787],
	["apps/rsa.c", 440, 185],
	["apps/rsautl.c", 376, 157],
	["apps/s_cb.c", 1658, 498],
	["apps/s_client.c", 2334, 912],
	["apps/s_server.c", 3506, 1322],
	["apps/s_socket.c", 614, 155],
	["apps/s_time.c", 642, 194],
	["apps/sess_id.c", 301, 108],
	["apps/smime.c", 779, 406],
	["apps/speed.c", 2875, 967],
	["apps/spkac.c", 313, 133],
	["apps/srp.c", 769, 264],
	["apps/ts.c", 1120, 442],
	["apps/verify.c", 353, 152],
	["apps/version.c", 215, 72],
	["apps/x509.c", 1276, 635],
	["crypto/aes/aes_cfb.c", 86, 3],
	["crypto/aes/aes_ctr.c", 64, 1],
	["crypto/aes/aes_ecb.c", 74, 7],
	["crypto/aes/aes_ige.c", 324, 56],
	["crypto/aes/aes_misc.c", 87, 10],
	["crypto/aes/aes_ofb.c", 62, 1],
	["crypto/aes/aes_wrap.c", 73, 9],
	["crypto/asn1/a_bitstr.c", 263, 57],
	["crypto/asn1/a_bool.c", 112, 17],
	["crypto/asn1/a_bytes.c", 307, 80],
	["crypto/asn1/a_d2i_fp.c", 285, 66],
	["crypto/asn1/a_digest.c", 112, 20],
	["crypto/asn1/a_dup.c", 118, 20],
	["crypto/asn1/a_enum.c", 182, 42],
	["crypto/asn1/a_gentm.c", 313, 67],
	["crypto/asn1/a_i2d_fp.c", 158, 34],
	["crypto/asn1/a_int.c", 465, 102],
	["crypto/asn1/a_mbstr.c", 424, 117],
	["crypto/asn1/a_object.c", 403, 108],
	["crypto/asn1/a_octet.c", 79, 5],
	["crypto/asn1/a_print.c", 130, 27],
	["crypto/asn1/a_set.c", 239, 50],
	["crypto/asn1/a_sign.c", 332, 72],
	["crypto/asn1/a_strex.c", 650, 217],
	["crypto/asn1/a_strnid.c", 314, 74],
	["crypto/asn1/a_time.c", 229, 72],
	["crypto/asn1/a_type.c", 156, 29],
	["crypto/asn1/a_utctm.c", 353, 79],
	["crypto/asn1/a_utf8.c", 238, 75],
	["crypto/asn1/a_verify.c", 232, 45],
	["crypto/asn1/ameth_lib.c", 485,77],
	["crypto/asn1/asn1_err.c", 355, 9],
	["crypto/asn1/asn1_gen.c", 832, 192],
	["crypto/asn1/asn1_lib.c", 480, 119],
	["crypto/asn1/asn1_par.c", 425, 150],
	["crypto/asn1/asn_mime.c", 975, 338],
	["crypto/asn1/asn_moid.c", 154, 59],
	["crypto/asn1/asn_pack.c", 208, 42],
	["crypto/asn1/bio_asn1.c", 483, 105],
	["crypto/asn1/bio_ndef.c", 249, 48],
	["crypto/asn1/d2i_pr.c", 176, 37],
	["crypto/asn1/d2i_pu.c", 137, 24],
	["crypto/asn1/evp_asn1.c", 196, 45],
	["crypto/asn1/f_enum.c", 204, 43],
	["crypto/asn1/f_int.c", 216, 46],
	["crypto/asn1/f_string.c", 210, 42],
	["crypto/asn1/i2d_pr.c", 79, 14],
	["crypto/asn1/i2d_pu.c", 94, 13],
	["crypto/asn1/n_pkey.c", 346, 102],
	["crypto/asn1/nsseq.c", 85, 8],
	["crypto/asn1/p5_pbe.c", 144, 36],
	["crypto/asn1/p5_pbev2.c", 281, 81],
	["crypto/asn1/p8_pkey.c", 146, 32],
	["crypto/asn1/t_bitst.c", 106, 28],
	["crypto/asn1/t_crl.c", 134, 36],
	["crypto/asn1/t_pkey.c", 114, 35],
	["crypto/asn1/t_req.c", 255, 94],
	["crypto/asn1/t_spki.c", 109, 25],
	["crypto/asn1/t_x509.c", 557, 229],
	["crypto/asn1/t_x509a.c", 116, 33],
	["crypto/asn1/tasn_dec.c", 1228,312],
	["crypto/asn1/tasn_enc.c", 660, 187],
	["crypto/asn1/tasn_fre.c", 250, 60],
	["crypto/asn1/tasn_new.c", 382, 98],
	["crypto/asn1/tasn_prn.c", 586, 222],
	["crypto/asn1/tasn_typ.c", 150, 5],
	["crypto/asn1/tasn_utl.c", 276, 53],
	["crypto/asn1/x_algor.c", 149, 37],
	["crypto/asn1/x_attrib.c", 125, 20],
	["crypto/asn1/x_bignum.c", 154, 29],
	["crypto/asn1/x_crl.c", 518, 127],
	["crypto/asn1/x_exten.c", 78, 5],
	["crypto/asn1/x_info.c", 118, 17],
	["crypto/asn1/x_long.c", 197, 29],
	["crypto/asn1/x_name.c", 539, 137],
	["crypto/asn1/x_nx509.c", 73, 5],
	["crypto/asn1/x_pkey.c", 154, 24],
	["crypto/asn1/x_pubkey.c", 375, 119],
	["crypto/asn1/x_req.c", 117, 9],
	["crypto/asn1/x_sig.c", 70, 5],
	["crypto/asn1/x_spki.c", 83, 5],
	["crypto/asn1/x_val.c", 70, 5],
	["crypto/asn1/x_x509.c", 240, 48],
	["crypto/asn1/x_x509a.c", 197, 59],
	["crypto/bf/bf_cfb64.c", 124, 7],
	["crypto/bf/bf_ecb.c", 101, 4],
	["crypto/bf/bf_enc.c", 301, 9],
	["crypto/bf/bf_ofb64.c", 111, 4],
	["crypto/bf/bf_skey.c", 126, 16],
	["crypto/bio/b_dump.c", 209, 57],
	["crypto/bio/b_print.c", 864, 231],
	["crypto/bio/b_sock.c", 963, 148],
	["crypto/bio/bf_buff.c", 518, 139],
	["crypto/bio/bf_nbio.c", 254, 60],
	["crypto/bio/bf_null.c", 190, 44],
	["crypto/bio/bio_cb.c", 146, 28],
	["crypto/bio/bio_err.c", 158, 9],
	["crypto/bio/bio_lib.c", 597, 178],
	["crypto/bio/bss_acpt.c", 464, 108],
	["crypto/bio/bss_bio.c", 887, 148],
	["crypto/bio/bss_conn.c", 613, 131],
	["crypto/bio/bss_dgram.c", 2082,124],
	["crypto/bio/bss_fd.c", 331, 46],
	["crypto/bio/bss_file.c", 473, 79],
	["crypto/bio/bss_log.c", 454, 29],
	["crypto/bio/bss_mem.c", 314, 55],
	["crypto/bio/bss_null.c", 150, 19],
	["crypto/bio/bss_sock.c", 288, 41],
	["crypto/bn/asm/x86_64-gcc.c", 639, 36],
	["crypto/bn/bn_add.c", 314, 62],
	["crypto/bn/bn_blind.c", 386, 97],
	["crypto/bn/bn_const.c", 548, 21],
	["crypto/bn/bn_ctx.c", 449, 53],
	["crypto/bn/bn_depr.c", 116, 17],
	["crypto/bn/bn_div.c", 478, 57],
	["crypto/bn/bn_err.c", 155, 9],
	["crypto/bn/bn_exp.c", 1458, 370],
	["crypto/bn/bn_exp2.c", 304, 77],
	["crypto/bn/bn_gcd.c", 703, 197],
	["crypto/bn/bn_gf2m.c", 1301, 244],
	["crypto/bn/bn_kron.c", 187, 34],
	["crypto/bn/bn_lib.c", 917, 176],
	["crypto/bn/bn_mod.c", 317, 98],
	["crypto/bn/bn_mont.c", 559, 97],
	["crypto/bn/bn_mpi.c", 129, 31],
	["crypto/bn/bn_mul.c", 1165, 252],
	["crypto/bn/bn_nist.c", 1263, 118],
	["crypto/bn/bn_prime.c", 516, 186],
	["crypto/bn/bn_print.c", 398, 121],
	["crypto/bn/bn_rand.c", 296, 73],
	["crypto/bn/bn_recp.c", 253, 81],
	["crypto/bn/bn_shift.c", 225, 39],
	["crypto/bn/bn_sqr.c", 291, 54],
	["crypto/bn/bn_sqrt.c", 410, 130],
	["crypto/bn/bn_word.c", 228, 53],
	["crypto/bn/bn_x931p.c", 278, 95],
	["crypto/bn/rsaz_exp.c", 347, 110],
	["crypto/buffer/buf_err.c", 98, 9],
	["crypto/buffer/buf_str.c", 138,28],
	["crypto/buffer/buffer.c", 188, 37],
	["crypto/camellia/cmll_cfb.c", 142, 3],
	["crypto/camellia/cmll_ctr.c", 65, 1],
	["crypto/camellia/cmll_ecb.c", 74, 2],
	["crypto/camellia/cmll_misc.c", 81, 13],
	["crypto/camellia/cmll_ofb.c", 123, 1],
	["crypto/camellia/cmll_utl.c", 65, 7],
	["crypto/cast/c_cfb64.c", 124, 8],
	["crypto/cast/c_ecb.c", 84, 4],
	["crypto/cast/c_enc.c", 201, 12],
	["crypto/cast/c_ofb64.c", 111, 5],
	["crypto/cast/c_skey.c", 176, 11],
	["crypto/cmac/cm_ameth.c", 97, 7],
	["crypto/cmac/cm_pmeth.c", 217, 73],
	["crypto/cmac/cmac.c", 307, 102],
	["crypto/cms/cms_asn1.c", 460, 55],
	["crypto/cms/cms_att.c", 198, 61],
	["crypto/cms/cms_cd.c", 135, 5],
	["crypto/cms/cms_dd.c", 146, 29],
	["crypto/cms/cms_enc.c", 261, 70],
	["crypto/cms/cms_env.c", 975, 259],
	["crypto/cms/cms_err.c", 310, 9],
	["crypto/cms/cms_ess.c", 396, 99],
	["crypto/cms/cms_io.c", 134, 31],
	["crypto/cms/cms_kari.c", 466, 165],
	["crypto/cms/cms_lib.c", 653, 219],
	["crypto/cms/cms_pwri.c", 436, 115],
	["crypto/cms/cms_sd.c", 958, 357],
	["crypto/cms/cms_smime.c", 837, 308],
	["crypto/comp/c_rle.c", 63, 15],
	["crypto/comp/c_zlib.c", 764, 6],
	["crypto/comp/comp_err.c", 99, 9],
	["crypto/comp/comp_lib.c", 67, 24],
	["crypto/conf/conf_api.c", 306, 65],
	["crypto/conf/conf_def.c", 707, 158],
	["crypto/conf/conf_err.c", 134, 9],
	["crypto/conf/conf_lib.c", 392, 103],
	["crypto/conf/conf_mall.c", 82, 8],
	["crypto/conf/conf_mod.c", 598, 167],
	["crypto/conf/conf_sap.c", 100, 10],
	["crypto/cpt_err.c", 105, 9],
	["crypto/cryptlib.c", 1031, 109],
	["crypto/cversion.c", 108, 16],
	["crypto/des/cbc_cksm.c", 104, 10],
	["crypto/des/cbc_enc.c", 62, 14],
	["crypto/des/cfb64ede.c", 250, 28],
	["crypto/des/cfb64enc.c", 123, 12],
	["crypto/des/cfb_enc.c", 200, 21],
	["crypto/des/des_enc.c", 390, 31],
	["crypto/des/des_old.c", 346, 53],
	["crypto/des/des_old2.c", 81, 6],
	["crypto/des/ecb3_enc.c", 83, 8],
	["crypto/des/ecb_enc.c", 125, 10],
	["crypto/des/ede_cbcm_enc.c", 190, 18],
	["crypto/des/enc_read.c", 236, 43],
	["crypto/des/enc_writ.c", 183, 29],
	["crypto/des/fcrypt.c", 168, 17],
	["crypto/des/fcrypt_b.c", 141, 6],
	["crypto/des/ofb64ede.c", 124, 9],
	["crypto/des/ofb64enc.c", 110, 9],
	["crypto/des/ofb_enc.c", 132, 14],
	["crypto/des/pcbc_enc.c", 116, 12],
	["crypto/des/qud_cksm.c", 144, 11],
	["crypto/des/rand_key.c", 68, 11],
	["crypto/des/read2pwd.c", 141, 17],
	["crypto/des/rpc_enc.c", 101, 10],
	["crypto/des/set_key.c", 448, 31],
	["crypto/des/str2key.c", 165, 32],
	["crypto/des/xcbc_enc.c", 217, 14],
	["crypto/dh/dh_ameth.c", 958, 348],
	["crypto/dh/dh_asn1.c", 190, 28],
	["crypto/dh/dh_check.c", 188, 64],
	["crypto/dh/dh_depr.c", 83, 11],
	["crypto/dh/dh_err.c", 127, 9],
	["crypto/dh/dh_gen.c", 205, 46],
	["crypto/dh/dh_kdf.c", 188, 56],
	["crypto/dh/dh_key.c", 290, 75],
	["crypto/dh/dh_lib.c", 264, 65],
	["crypto/dh/dh_pmeth.c", 552, 158],
	["crypto/dh/dh_prn.c", 80, 12],
	["crypto/dh/dh_rfc5114.c", 286, 5],
	["crypto/dsa/dsa_ameth.c", 679, 227],
	["crypto/dsa/dsa_asn1.c", 203, 41],
	["crypto/dsa/dsa_depr.c", 114, 11],
	["crypto/dsa/dsa_err.c", 134, 9],
	["crypto/dsa/dsa_gen.c", 749, 308],
	["crypto/dsa/dsa_key.c", 146, 31],
	["crypto/dsa/dsa_lib.c", 330, 89],
	["crypto/dsa/dsa_ossl.c", 423, 122],
	["crypto/dsa/dsa_pmeth.c", 313, 83],
	["crypto/dsa/dsa_prn.c", 120, 33],
	["crypto/dsa/dsa_sign.c", 111, 16],
	["crypto/dsa/dsa_vrf.c", 76, 7],
	["crypto/dso/dso_beos.c", 254, 5],
	["crypto/dso/dso_dl.c", 381, 5],
	["crypto/dso/dso_dlfcn.c", 466, 97],
	["crypto/dso/dso_err.c", 159, 9],
	["crypto/dso/dso_lib.c", 449, 136],
	["crypto/dso/dso_null.c", 93, 6],
	["crypto/dso/dso_openssl.c", 84,7],
	["crypto/dso/dso_vms.c", 548, 5],
	["crypto/dso/dso_win32.c", 789, 5],
	["crypto/ebcdic.c", 285, 0],
	["crypto/ec/ec2_mult.c", 464, 181],
	["crypto/ec/ec2_oct.c", 404, 132],
	["crypto/ec/ec2_smpl.c", 799, 305],
	["crypto/ec/ec_ameth.c", 966, 397],
	["crypto/ec/ec_asn1.c", 1327, 367],
	["crypto/ec/ec_check.c", 121, 31],
	["crypto/ec/ec_curve.c", 3249, 71],
	["crypto/ec/ec_cvt.c", 181, 29],
	["crypto/ec/ec_err.c", 333, 9],
	["crypto/ec/ec_key.c", 566, 180],
	["crypto/ec/ec_lib.c", 1135, 401],
	["crypto/ec/ec_mult.c", 914, 204],
	["crypto/ec/ec_oct.c", 193, 53],
	["crypto/ec/ec_pmeth.c", 531, 183],
	["crypto/ec/ec_print.c", 180, 37],
	["crypto/ec/eck_prn.c", 378, 167],
	["crypto/ec/ecp_mont.c", 309, 82],
	["crypto/ec/ecp_nist.c", 221, 57],
	["crypto/ec/ecp_nistp224.c", 1770, 0],
	["crypto/ec/ecp_nistp256.c", 2370, 0],
	["crypto/ec/ecp_nistp521.c", 2149, 0],
	["crypto/ec/ecp_nistputil.c", 219, 0],
	["crypto/ec/ecp_nistz256.c", 1522, 291],
	["crypto/ec/ecp_oct.c", 429, 148],
	["crypto/ec/ecp_smpl.c", 1419, 636],
	["crypto/ecdh/ech_err.c", 99, 9],
	["crypto/ecdh/ech_kdf.c", 112, 26],
	["crypto/ecdh/ech_key.c", 82, 10],
	["crypto/ecdh/ech_lib.c", 266, 53],
	["crypto/ecdh/ech_ossl.c", 219, 51],
	["crypto/ecdsa/ecs_asn1.c", 68, 5],
	["crypto/ecdsa/ecs_err.c", 108, 9],
	["crypto/ecdsa/ecs_lib.c", 355, 75],
	["crypto/ecdsa/ecs_ossl.c", 465,164],
	["crypto/ecdsa/ecs_sign.c", 107,25],
	["crypto/ecdsa/ecs_vrf.c", 113, 23],
	["crypto/engine/eng_all.c", 137,13],
	["crypto/engine/eng_cnf.c", 243,79],
	["crypto/engine/eng_cryptodev.c", 1536, 5],
	["crypto/engine/eng_ctrl.c", 386, 130],
	["crypto/engine/eng_dyn.c", 571,140],
	["crypto/engine/eng_err.c", 182,9],
	["crypto/engine/eng_fat.c", 182,86],
	["crypto/engine/eng_init.c", 158, 29],
	["crypto/engine/eng_lib.c", 348,68],
	["crypto/engine/eng_list.c", 406, 84],
	["crypto/engine/eng_openssl.c", 403, 67],
	["crypto/engine/eng_pkey.c", 187, 39],
	["crypto/engine/eng_rdrand.c", 150, 37],
	["crypto/engine/eng_table.c", 359, 60],
	["crypto/engine/tb_asnmth.c", 247, 56],
	["crypto/engine/tb_cipher.c", 144, 31],
	["crypto/engine/tb_dh.c", 125, 23],
	["crypto/engine/tb_digest.c", 144, 31],
	["crypto/engine/tb_dsa.c", 125, 23],
	["crypto/engine/tb_ecdh.c", 140,23],
	["crypto/engine/tb_ecdsa.c", 125, 23],
	["crypto/engine/tb_pkmeth.c", 167, 37],
	["crypto/engine/tb_rand.c", 125,23],
	["crypto/engine/tb_rsa.c", 125, 23],
	["crypto/engine/tb_store.c", 130, 17],
	["crypto/err/err.c", 1146, 183],
	["crypto/err/err_all.c", 169, 33],
	["crypto/err/err_prn.c", 114, 22],
	["crypto/evp/bio_b64.c", 574, 114],
	["crypto/evp/bio_enc.c", 429, 87],
	["crypto/evp/bio_md.c", 273, 65],
	["crypto/evp/bio_ok.c", 625, 140],
	["crypto/evp/c_all.c", 91, 9],
	["crypto/evp/c_allc.c", 242, 185],
	["crypto/evp/c_alld.c", 115, 33],
	["crypto/evp/digest.c", 409, 101],
	["crypto/evp/e_aes.c", 2025, 370],
	["crypto/evp/e_aes_cbc_hmac_sha1.c", 1009, 158],
	["crypto/evp/e_aes_cbc_hmac_sha256.c", 986, 157],
	["crypto/evp/e_bf.c", 88, 8],
	["crypto/evp/e_camellia.c", 395,35],
	["crypto/evp/e_cast.c", 90, 8],
	["crypto/evp/e_des.c", 270, 45],
	["crypto/evp/e_des3.c", 496, 102],
	["crypto/evp/e_idea.c", 120, 14],
	["crypto/evp/e_null.c", 101, 10],
	["crypto/evp/e_old.c", 165, 25],
	["crypto/evp/e_rc2.c", 236, 52],
	["crypto/evp/e_rc4.c", 134, 12],
	["crypto/evp/e_rc4_hmac_md5.c", 309, 65],
	["crypto/evp/e_rc5.c", 123, 5],
	["crypto/evp/e_seed.c", 83, 7],
	["crypto/evp/e_xcbc_d.c", 131, 15],
	["crypto/evp/encode.c", 461, 63],
	["crypto/evp/evp_acnf.c", 74, 7],
	["crypto/evp/evp_cnf.c", 119, 42],
	["crypto/evp/evp_enc.c", 667, 206],
	["crypto/evp/evp_err.c", 255, 9],
	["crypto/evp/evp_key.c", 196, 57],
	["crypto/evp/evp_lib.c", 392, 61],
	["crypto/evp/evp_pbe.c", 313, 55],
	["crypto/evp/evp_pkey.c", 230, 59],
	["crypto/evp/m_dss.c", 105, 12],
	["crypto/evp/m_dss1.c", 106, 12],
	["crypto/evp/m_ecdsa.c", 155, 12],
	["crypto/evp/m_md2.c", 107, 5],
	["crypto/evp/m_md4.c", 109, 12],
	["crypto/evp/m_md5.c", 108, 12],
	["crypto/evp/m_mdc2.c", 109, 12],
	["crypto/evp/m_null.c", 99, 9],
	["crypto/evp/m_ripemd.c", 108, 12],
	["crypto/evp/m_sha.c", 107, 12],
	["crypto/evp/m_sha1.c", 236, 32],
	["crypto/evp/m_sigver.c", 204, 89],
	["crypto/evp/m_wp.c", 49, 12],
	["crypto/evp/names.c", 216, 56],
	["crypto/evp/p5_crpt.c", 150, 47],
	["crypto/evp/p5_crpt2.c", 335, 84],
	["crypto/evp/p_dec.c", 88, 8],
	["crypto/evp/p_enc.c", 88, 8],
	["crypto/evp/p_lib.c", 457, 139],
	["crypto/evp/p_open.c", 130, 27],
	["crypto/evp/p_seal.c", 122, 33],
	["crypto/evp/p_sign.c", 134, 30],
	["crypto/evp/p_verify.c", 117, 28],
	["crypto/evp/pmeth_fn.c", 347, 106],
	["crypto/evp/pmeth_gn.c", 221, 64],
	["crypto/evp/pmeth_lib.c", 614, 92],
	["crypto/ex_data.c", 647, 86],
	["crypto/fips_ers.c", 8, 0],
	["crypto/hmac/hm_ameth.c", 168, 25],
	["crypto/hmac/hm_pmeth.c", 263, 72],
	["crypto/hmac/hmac.c", 269, 90],
	["crypto/idea/i_cbc.c", 172, 9],
	["crypto/idea/i_cfb64.c", 124, 7],
	["crypto/idea/i_ecb.c", 89, 4],
	["crypto/idea/i_ofb64.c", 111, 4],
	["crypto/idea/i_skey.c", 172, 15],
	["crypto/krb5/krb5_asn.c", 163, 5],
	["crypto/lhash/lh_stats.c", 247,46],
	["crypto/lhash/lhash.c", 459, 59],
	["crypto/md4/md4_dgst.c", 200, 26],
	["crypto/md4/md4_one.c", 97, 12],
	["crypto/md5/md5_dgst.c", 217, 25],
	["crypto/md5/md5_one.c", 97, 12],
	["crypto/mdc2/mdc2_one.c", 77, 12],
	["crypto/mdc2/mdc2dgst.c", 197, 33],
	["crypto/mem.c", 467, 117],
	["crypto/mem_dbg.c", 831, 114],
	["crypto/modes/cbc128.c", 208, 38],
	["crypto/modes/ccm128.c", 480, 92],
	["crypto/modes/cfb128.c", 255, 41],
	["crypto/modes/ctr128.c", 264, 34],
	["crypto/modes/cts128.c", 545, 91],
	["crypto/modes/gcm128.c", 2372, 146],
	["crypto/modes/ofb128.c", 125, 16],
	["crypto/modes/wrap128.c", 139, 34],
	["crypto/modes/xts128.c", 205, 26],
	["crypto/o_dir.c", 87, 24],
	["crypto/o_fips.c", 97, 11],
	["crypto/o_init.c", 84, 6],
	["crypto/o_str.c", 117, 29],
	["crypto/o_time.c", 441, 29],
	["crypto/objects/o_names.c", 367, 66],
	["crypto/objects/obj_dat.c", 802, 266],
	["crypto/objects/obj_err.c", 101, 9],
	["crypto/objects/obj_lib.c", 136, 33],
	["crypto/objects/obj_xref.c", 223, 42],
	["crypto/ocsp/ocsp_asn.c", 184, 5],
	["crypto/ocsp/ocsp_cl.c", 384, 103],
	["crypto/ocsp/ocsp_err.c", 150, 9],
	["crypto/ocsp/ocsp_ext.c", 567, 171],
	["crypto/ocsp/ocsp_ht.c", 556, 171],
	["crypto/ocsp/ocsp_lib.c", 285, 81],
	["crypto/ocsp/ocsp_prn.c", 300, 123],
	["crypto/ocsp/ocsp_srv.c", 272, 84],
	["crypto/ocsp/ocsp_vfy.c", 455, 144],
	["crypto/pem/pem_all.c", 428, 44],
	["crypto/pem/pem_err.c", 169, 9],
	["crypto/pem/pem_info.c", 395, 118],
	["crypto/pem/pem_lib.c", 866, 358],
	["crypto/pem/pem_oth.c", 87, 10],
	["crypto/pem/pem_pk8.c", 260, 76],
	["crypto/pem/pem_pkey.c", 294, 95],
	["crypto/pem/pem_seal.c", 192, 42],
	["crypto/pem/pem_sign.c", 102, 13],
	["crypto/pem/pem_x509.c", 69, 5],
	["crypto/pem/pem_xaux.c", 71, 5],
	["crypto/pem/pvkfmt.c", 889, 331],
	["crypto/pkcs12/p12_add.c", 259,63],
	["crypto/pkcs12/p12_asn.c", 126,5],
	["crypto/pkcs12/p12_attr.c", 148, 33],
	["crypto/pkcs12/p12_crpt.c", 120, 27],
	["crypto/pkcs12/p12_crt.c", 359,110],
	["crypto/pkcs12/p12_decr.c", 203, 34],
	["crypto/pkcs12/p12_init.c", 93,14],
	["crypto/pkcs12/p12_key.c", 239,65],
	["crypto/pkcs12/p12_kiss.c", 300, 100],
	["crypto/pkcs12/p12_mutl.c", 196, 67],
	["crypto/pkcs12/p12_npas.c", 236, 77],
	["crypto/pkcs12/p12_p8d.c", 71, 7],
	["crypto/pkcs12/p12_p8e.c", 106,20],
	["crypto/pkcs12/p12_utl.c", 162,32],
	["crypto/pkcs12/pk12err.c", 150,9],
	["crypto/pkcs7/bio_pk7.c", 71, 7],
	["crypto/pkcs7/pk7_asn1.c", 252,22],
	["crypto/pkcs7/pk7_attr.c", 166,52],
	["crypto/pkcs7/pk7_doit.c", 1296, 397],
	["crypto/pkcs7/pk7_lib.c", 647, 198],
	["crypto/pkcs7/pk7_mime.c", 97, 37],
	["crypto/pkcs7/pk7_smime.c", 591, 201],
	["crypto/pkcs7/pkcs7err.c", 208,9],
	["crypto/pqueue/pqueue.c", 236, 41],
	["crypto/rand/md_rand.c", 593, 75],
	["crypto/rand/rand_egd.c", 293, 39],
	["crypto/rand/rand_err.c", 101, 9],
	["crypto/rand/rand_lib.c", 301, 52],
	["crypto/rand/rand_nw.c", 180, 5],
	["crypto/rand/rand_os2.c", 171, 5],
	["crypto/rand/rand_unix.c", 448,11],
	["crypto/rand/rand_win.c", 753, 5],
	["crypto/rand/randfile.c", 338, 70],
	["crypto/rc2/rc2_cbc.c", 229, 13],
	["crypto/rc2/rc2_ecb.c", 93, 3],
	["crypto/rc2/rc2_skey.c", 158, 12],
	["crypto/rc2/rc2cfb64.c", 124, 7],
	["crypto/rc2/rc2ofb64.c", 111, 4],
	["crypto/rc4/rc4_utl.c", 63, 6],
	["crypto/ripemd/rmd_dgst.c", 335, 26],
	["crypto/ripemd/rmd_one.c", 78, 12],
	["crypto/rsa/rsa_ameth.c", 960, 412],
	["crypto/rsa/rsa_asn1.c", 132, 18],
	["crypto/rsa/rsa_chk.c", 215, 69],
	["crypto/rsa/rsa_crpt.c", 248, 63],
	["crypto/rsa/rsa_depr.c", 108, 21],
	["crypto/rsa/rsa_eay.c", 905, 264],
	["crypto/rsa/rsa_err.c", 248, 9],
	["crypto/rsa/rsa_gen.c", 251, 85],
	["crypto/rsa/rsa_lib.c", 337, 84],
	["crypto/rsa/rsa_none.c", 95, 16],
	["crypto/rsa/rsa_null.c", 156, 12],
	["crypto/rsa/rsa_oaep.c", 284, 109],
	["crypto/rsa/rsa_pk1.c", 276, 82],
	["crypto/rsa/rsa_pmeth.c", 785, 288],
	["crypto/rsa/rsa_prn.c", 93, 19],
	["crypto/rsa/rsa_pss.c", 291, 76],
	["crypto/rsa/rsa_saos.c", 149, 30],
	["crypto/rsa/rsa_sign.c", 302, 80],
	["crypto/rsa/rsa_ssl.c", 150, 34],
	["crypto/rsa/rsa_x931.c", 168, 31],
	["crypto/seed/seed.c", 712, 5],
	["crypto/seed/seed_cbc.c", 66, 8],
	["crypto/seed/seed_cfb.c", 119, 6],
	["crypto/seed/seed_ecb.c", 62, 8],
	["crypto/seed/seed_ofb.c", 118, 6],
	["crypto/sha/sha1_one.c", 80, 12],
	["crypto/sha/sha1dgst.c", 75, 25],
	["crypto/sha/sha256.c", 388, 43],
	["crypto/sha/sha512.c", 685, 51],
	["crypto/sha/sha_dgst.c", 75, 27],
	["crypto/sha/sha_one.c", 80, 12],
	["crypto/srp/srp_lib.c", 358, 152],
	["crypto/srp/srp_vfy.c", 706, 210],
	["crypto/stack/stack.c", 385, 109],
	["crypto/ts/ts_asn1.c", 327, 32],
	["crypto/ts/ts_conf.c", 492, 172],
	["crypto/ts/ts_err.c", 189, 9],
	["crypto/ts/ts_lib.c", 144, 41],
	["crypto/ts/ts_req_print.c", 105, 27],
	["crypto/ts/ts_req_utils.c", 233, 64],
	["crypto/ts/ts_rsp_print.c", 282, 102],
	["crypto/ts/ts_rsp_sign.c", 1021, 330],
	["crypto/ts/ts_rsp_utils.c", 397, 122],
	["crypto/ts/ts_rsp_verify.c", 738, 185],
	["crypto/ts/ts_verify_ctx.c", 163, 44],
	["crypto/txt_db/txt_db.c", 382, 100],
	["crypto/ui/ui_compat.c", 70, 9],
	["crypto/ui/ui_err.c", 112, 9],
	["crypto/ui/ui_lib.c", 871, 241],
	["crypto/ui/ui_openssl.c", 718, 113],
	["crypto/ui/ui_util.c", 94, 20],
	["crypto/uid.c", 89, 7],
	["crypto/whrlpool/wp_dgst.c", 258, 54],
	["crypto/x509/by_dir.c", 437, 91],
	["crypto/x509/by_file.c", 278, 79],
	["crypto/x509/x509_att.c", 385, 135],
	["crypto/x509/x509_cmp.c", 499, 166],
	["crypto/x509/x509_d2.c", 110, 30],
	["crypto/x509/x509_def.c", 93, 11],
	["crypto/x509/x509_err.c", 188, 9],
	["crypto/x509/x509_ext.c", 212, 59],
	["crypto/x509/x509_lu.c", 711, 191],
	["crypto/x509/x509_obj.c", 231, 43],
	["crypto/x509/x509_r2x.c", 114, 28],
	["crypto/x509/x509_req.c", 329, 92],
	["crypto/x509/x509_set.c", 153, 41],
	["crypto/x509/x509_trs.c", 319, 79],
	["crypto/x509/x509_txt.c", 212, 71],
	["crypto/x509/x509_v3.c", 285, 92],
	["crypto/x509/x509_vfy.c", 2498,757],
	["crypto/x509/x509_vpm.c", 663, 144],
	["crypto/x509/x509cset.c", 168, 38],
	["crypto/x509/x509name.c", 398, 133],
	["crypto/x509/x509rset.c", 86, 17],
	["crypto/x509/x509spki.c", 124, 25],
	["crypto/x509/x509type.c", 128, 19],
	["crypto/x509/x_all.c", 559, 111],
	["crypto/x509v3/pcy_cache.c", 270, 67],
	["crypto/x509v3/pcy_data.c", 130, 19],
	["crypto/x509v3/pcy_lib.c", 168,31],
	["crypto/x509v3/pcy_map.c", 131,19],
	["crypto/x509v3/pcy_node.c", 191, 40],
	["crypto/x509v3/pcy_tree.c", 832, 198],
	["crypto/x509v3/v3_addr.c", 1345, 5],
	["crypto/x509v3/v3_akey.c", 206,45],
	["crypto/x509v3/v3_akeya.c", 74,5],
	["crypto/x509v3/v3_alt.c", 610, 181],
	["crypto/x509v3/v3_asid.c", 897,5],
	["crypto/x509v3/v3_bcons.c", 133, 21],
	["crypto/x509v3/v3_bitst.c", 143, 20],
	["crypto/x509v3/v3_conf.c", 533,181],
	["crypto/x509v3/v3_cpols.c", 492, 131],
	["crypto/x509v3/v3_crld.c", 563,190],
	["crypto/x509v3/v3_enum.c", 101,12],
	["crypto/x509v3/v3_extku.c", 150, 15],
	["crypto/x509v3/v3_genn.c", 251,43],
	["crypto/x509v3/v3_ia5.c", 120, 15],
	["crypto/x509v3/v3_info.c", 211,33],
	["crypto/x509v3/v3_int.c", 93, 7],
	["crypto/x509v3/v3_lib.c", 364, 95],
	["crypto/x509v3/v3_ncons.c", 480, 130],
	["crypto/x509v3/v3_ocsp.c", 313,79],
	["crypto/x509v3/v3_pci.c", 318, 89],
	["crypto/x509v3/v3_pcia.c", 57, 5],
	["crypto/x509v3/v3_pcons.c", 140, 22],
	["crypto/x509v3/v3_pku.c", 115, 15],
	["crypto/x509v3/v3_pmaps.c", 157, 19],
	["crypto/x509v3/v3_prn.c", 260, 85],
	["crypto/x509v3/v3_purp.c", 853,254],
	["crypto/x509v3/v3_scts.c", 335,63],
	["crypto/x509v3/v3_skey.c", 151,26],
	["crypto/x509v3/v3_sxnet.c", 274, 60],
	["crypto/x509v3/v3_utl.c", 1352,472],
	["crypto/x509v3/v3err.c", 250, 9],
	["ssl/bio_ssl.c", 592, 156],
	["ssl/d1_both.c", 1581, 319],
	["ssl/d1_clnt.c", 870, 129],
	["ssl/d1_lib.c", 574, 154],
	["ssl/d1_meth.c", 91, 14],
	["ssl/d1_pkt.c", 1922, 333],
	["ssl/d1_srtp.c", 449, 71],
	["ssl/d1_srvr.c", 981, 141],
	["ssl/kssl.c", 2261, 5],
	["ssl/s23_clnt.c", 803, 147],
	["ssl/s23_lib.c", 186, 46],
	["ssl/s23_meth.c", 90, 15],
	["ssl/s23_pkt.c", 114, 17],
	["ssl/s23_srvr.c", 653, 107],
	["ssl/s2_clnt.c", 1095, 5],
	["ssl/s2_enc.c", 198, 5],
	["ssl/s2_lib.c", 571, 5],
	["ssl/s2_meth.c", 92, 5],
	["ssl/s2_pkt.c", 726, 5],
	["ssl/s2_srvr.c", 1172, 5],
	["ssl/s3_both.c", 748, 127],
	["ssl/s3_cbc.c", 821, 146],
	["ssl/s3_clnt.c", 3764, 790],
	["ssl/s3_enc.c", 971, 276],
	["ssl/s3_lib.c", 4537, 427],
	["ssl/s3_meth.c", 75, 9],
	["ssl/s3_pkt.c", 1749, 333],
	["ssl/s3_srvr.c", 3615, 714],
	["ssl/ssl_algs.c", 156, 62],
	["ssl/ssl_asn1.c", 637, 94],
	["ssl/ssl_cert.c", 1265, 360],
	["ssl/ssl_ciph.c", 2078, 328],
	["ssl/ssl_conf.c", 692, 204],
	["ssl/ssl_err.c", 838, 9],
	["ssl/ssl_err2.c", 70, 7],
	["ssl/ssl_lib.c", 3572, 871],
	["ssl/ssl_rsa.c", 1044, 314],
	["ssl/ssl_sess.c", 1274, 272],
	["ssl/ssl_stat.c", 1079, 27],
	["ssl/ssl_txt.c", 263, 97],
	["ssl/ssl_utst.c", 73, 5],
	["ssl/t1_clnt.c", 91, 14],
	["ssl/t1_enc.c", 1378, 322],
	["ssl/t1_ext.c", 299, 64],
	["ssl/t1_lib.c", 4440, 1070],
	["ssl/t1_meth.c", 85, 14],
	["ssl/t1_reneg.c", 293, 39],
	["ssl/t1_srvr.c", 93, 14],
	["ssl/t1_trce.c", 1267, 5],
	["ssl/tls_srp.c", 543, 176],
]);

# Check that at least something has executed.
$viewer->cmp_dynamic_data();

$exp->hard_close();
$viewer->close();

open( my $fh, ">", "check.good" );
print $fh <<EOF;
Checking ...done

Summary:
        58 Log files found
       752 Source files input
       868 Calls to the instrumentation tool
       752 Forked compilers
       752 Instrument successes
        58 Application link commands
       752 Warnings during source parsing

Totals:
    322027 Lines of source code
     24064 Lines of instrumentation header
        43 Functions called 'main'
     10574 Function definitions
     25212 If statements
      1486 For loops
       476 While loops
        76 Do while loops
       334 Switch statements
     10801 Return statement values
     31196 Call expressions
   2611342 Total statements
     16412 Errors rewriting source
EOF

system("$ENV{CITRUN_TOOLS}/citrun-check /usr/ports/pobj/openssl-* > check.out");
system("diff -u check.good check.out");
$package->clean();
