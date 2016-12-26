#!/bin/sh -u
#
# Test that building Mutt works.
#
. tt/package.subr "mail/mutt"
plan 11

pkg_check_deps
pkg_clean
pkg_build
pkg_test

cat <<EOF > check.good
Summary:
       218 Source files used as input
        73 Application link commands
       209 Rewrite successes
         9 Rewrite failures
       194 Rewritten source compile successes
        15 Rewritten source compile failures

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
pkg_check

cat <<EOF > tu_list.good
account.c 241
addrbook.c 246
alias.c 658
ascii.c 107
attach.c 1043
auth.c 114
auth_anon.c 77
auth_cram.c 181
auth_login.c 74
base64.c 123
bcache.c 268
browse.c 472
browser.c 1267
buffy.c 629
charset.c 680
color.c 824
command.c 1042
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
imap.c 2041
init.c 3285
keymap.c 1150
lib.c 1086
main.c 1249
mbox.c 1269
mbyte.c 569
md5.c 475
menu.c 1082
message.c 1308
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
utf7.c 292
util.c 852
EOF

$workdir/mutt < /dev/null > /dev/null
ok "is write_tus.pl exit code 0" \
	perl -I$treedir $treedir/tt/write_tus.pl ${CITRUN_PROCDIR}mutt_*
pkg_check_manifest

pkg_clean
