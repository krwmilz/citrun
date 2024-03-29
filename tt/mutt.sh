#!/bin/sh -eu
#
# Test that building Mutt works.
#
. tt/openbsd.subr 'mail' 'mutt'
plan 18

pkg_clean

pkg_extract
pkg_check_deps
pkg_build
#pkg_test

pkg_extract_instrumented
pkg_build_instrumented

pkg_scrub_logs $workdist/config.log $workdist_inst/config.log
pkg_diff_build_logs

#ok 'is config.log identical' \
#	diff -u $workdist/config.log $workdist_inst/config.log

ok 'is size exit code 0' size $workdist/mutt $workdist_inst/mutt

#pkg_diff_symbols mutt

cat <<EOF > $workdir_inst/check.good
Summary:
       218 Source files used as input
        73 Application link commands
       194 Successful modified source compiles
        24 Failed modified source compiles

Totals:
     94664 Lines of source code
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
pkg_citrun_check

cat <<EOF > $workdir_inst/tu_list.good
account.c 241
addrbook.c 246
alias.c 658
ascii.c 107
attach.c 1043
base64.c 123
bcache.c 268
browser.c 1267
buffy.c 629
charset.c 680
color.c 824
commands.c 1019
complete.c 199
compose.c 1345
conststrings.c 75
copy.c 962
crypt-mod-pgp-classic.c 138
crypt-mod-smime-classic.c 119
crypt-mod.c 59
crypt.c 1121
cryptglue.c 396
curs_lib.c 1046
curs_main.c 2349
date.c 191
edit.c 491
editmsg.c 235
enter.c 772
filter.c 184
flags.c 401
from.c 199
getdomain.c 70
gnupgparse.c 446
group.c 209
handler.c 1845
hash.c 179
hcache.c 1242
hdrline.c 764
headers.c 214
help.c 380
history.c 320
hook.c 545
auth.c 114
auth_anon.c 77
auth_cram.c 181
auth_login.c 74
browse.c 472
command.c 1042
imap.c 2041
message.c 1308
utf7.c 292
util.c 852
init.c 3285
keymap.c 1150
lib.c 1086
main.c 1249
mbox.c 1269
mbyte.c 569
md5.c 475
menu.c 1082
mh.c 2351
mutt_idna.c 343
mutt_socket.c 584
mutt_ssl.c 1125
mutt_tunnel.c 194
muttlib.c 1960
mx.c 1691
pager.c 2817
parse.c 1648
patchlist.c 13
pattern.c 1546
pgp.c 1866
pgpinvoke.c 358
pgpkey.c 1045
pgplib.c 253
pgpmicalg.c 212
pgppacket.c 232
pop.c 931
pop_auth.c 418
pop_lib.c 597
postpone.c 751
query.c 543
recvattach.c 1274
recvcmd.c 950
resize.c 80
rfc1524.c 594
rfc2047.c 924
rfc2231.c 384
rfc3676.c 390
rfc822.c 919
safe_asprintf.c 96
score.c 196
send.c 1954
sendlib.c 2890
signal.c 254
smime.c 2280
smtp.c 666
sort.c 343
status.c 309
system.c 142
thread.c 1431
url.c 325
EOF

# Run instrumented Mutt and make sure a process file was created.
$workdist_inst/mutt -h > /dev/null
ok 'is instrumented mutt exit code 0' test $? -eq 0

ok "is write_tus.pl exit code 0" \
	tt/write_tus.pl $workdir_inst/tu_list.out ${CITRUN_PROCDIR}mutt_*
ok "translation unit manifest" \
	diff -u $workdir_inst/tu_list.good $workdir_inst/tu_list.out

pkg_clean
