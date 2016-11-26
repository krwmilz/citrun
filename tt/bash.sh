#!/bin/sh -u
#
# Check that Bash works with C It Run.
#
. tt/package.subr "shells/bash"
plan 11

enter_tmpdir

pkg_check_deps
pkg_clean
pkg_build
pkg_test

cat <<EOF > check.good
Summary:
       351 Source files used as input
       100 Application link commands
       190 Rewrite parse warnings
        31 Rewrite parse errors
       322 Rewrite successes
        29 Rewrite failures
       299 Rewritten source compile successes
        23 Rewritten source compile failures

Totals:
    165776 Lines of source code
      2698 Function definitions
      5514 If statements
       638 For loops
       312 While loops
        38 Do while loops
       140 Switch statements
      3051 Return statement values
      8263 Call expressions
    179568 Total statements
     18691 Binary operators
       549 Errors rewriting source
EOF
pkg_check

cat <<EOF > tu_list.good
./tilde.c 503
alias.c 242
alias.c 581
array.c 1149
arrayfunc.c 1155
assoc.c 562
bashgetopt.c 176
bashhist.c 924
bashline.c 4235
bind.c 2484
bind.c 342
bracecomp.c 222
braces.c 836
break.c 142
builtin.c 86
builtins.c 2055
callback.c 294
caller.c 155
casemod.c 266
cd.c 662
colon.c 68
colors.c 252
command.c 220
common.c 891
complete.c 2894
complete.c 872
copy_cmd.c 451
declare.c 697
display.c 2825
dispose_cmd.c 343
eaccess.c 243
echo.c 201
enable.c 484
error.c 490
eval.c 292
eval.c 58
evalfile.c 357
evalstring.c 643
exec.c 253
execute_cmd.c 5463
exit.c 169
expr.c 1568
fc.c 699
fg_bg.c 187
findcmd.c 624
flags.c 366
fmtulong.c 192
fmtumax.c 28
fnxform.c 200
funmap.c 267
general.c 1178
getopt.c 310
getopts.c 332
glob.c 1392
gmisc.c 411
hash.c 284
hashcmd.c 197
hashlib.c 443
help.c 518
histexpand.c 1659
histfile.c 585
history.c 382
history.c 520
histsearch.c 195
input.c 634
input.c 667
input_avail.c 99
isearch.c 790
itos.c 85
jobs.c 299
jobs.c 4479
keymaps.c 163
kill.c 266
kill.c 695
let.c 130
list.c 137
locale.c 564
macro.c 308
mailcheck.c 492
mailstat.c 160
make_cmd.c 893
makepath.c 129
mapfile.c 362
mbschr.c 86
mbutil.c 379
misc.c 693
netconn.c 83
netopen.c 351
nls.c 282
oslib.c 302
parens.c 174
parse-colors.c 441
pathcanon.c 235
pathexp.c 610
pathphys.c 297
pcomplete.c 1663
pcomplib.c 229
print_cmd.c 1592
printf.c 1271
pushd.c 785
read.c 1122
readline.c 1365
redir.c 1401
return.c 79
rltty.c 976
search.c 632
set.c 891
setattr.c 552
setlinebuf.c 64
shell.c 1898
shift.c 102
shmatch.c 121
shmbchar.c 114
shopt.c 778
shquote.c 328
shtty.c 331
sig.c 740
signals.c 710
smatch.c 416
source.c 198
spell.c 213
strchrnul.c 36
stringlib.c 288
stringlist.c 298
stringvec.c 249
strmatch.c 80
strtrans.c 381
subst.c 9767
suspend.c 128
syntax.c 270
terminal.c 795
test.c 160
test.c 881
text.c 1706
times.c 120
timeval.c 146
tmpfile.c 223
trap.c 1266
trap.c 305
type.c 406
uconvert.c 117
ufuncs.c 105
ulimit.c 784
umask.c 313
undo.c 355
unicode.c 344
unwind_prot.c 358
util.c 592
variables.c 5396
version.c 95
vi_mode.c 2179
wait.c 217
wcsnwidth.c 57
winsize.c 97
xmalloc.c 224
xmbsrtowcs.c 410
y.tab.c 6270
zcatfd.c 71
zgetline.c 122
zmapfd.c 90
zread.c 219
zwrite.c 65
EOF

$workdir/bash < /dev/null

ok "is write_tus.pl exit code 0" \
	perl -I$treedir $treedir/tt/write_tus.pl ${CITRUN_PROCDIR}bash_*

ok "sorting" sort -o tu_list.out tu_list.out
ok "translation unit manifest" diff -u tu_list.good tu_list.out

pkg_clean
