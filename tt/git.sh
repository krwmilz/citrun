#!/bin/sh
#
# Instruments git, checks logs, and makes sure the resulting program still
# works.
#
. tlib/package.sh
plan 8

pkg_set "devel/git"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
       381 Source files used as input
        82 Application link commands
        45 Rewrite parse warnings
         5 Rewrite parse errors
       376 Rewrite successes
         5 Rewrite failures
       374 Rewritten source compile successes
         2 Rewritten source compile failures

Totals:
    185689 Lines of source code
      6015 Function definitions
     16473 If statements
      1497 For loops
      1025 While loops
        71 Do while loops
       272 Switch statements
      6825 Return statement values
     30619 Call expressions
    528570 Total statements
     34625 Binary operators
      1530 Errors rewriting source
EOF
pkg_check

# Start git doing something that will take a while. At my own expense.
$TEST_WRKDIST/git clone http://git.0x30.net/citrun citrun_TEST_CLONE &
pid=$!

sleep 1

cat <<EOF > filelist.good
abspath.c 181
advice.c 120
alias.c 78
alloc.c 116
archive-tar.c 454
archive-zip.c 586
archive.c 561
argv-array.c 88
attr.c 826
base85.c 133
bisect.c 1034
blob.c 19
branch.c 372
builtin/add.c 459
builtin/am.c 2429
builtin/annotate.c 23
builtin/apply.c 4666
builtin/archive.c 110
builtin/bisect--helper.c 32
builtin/blame.c 2882
builtin/branch.c 876
builtin/bundle.c 74
builtin/cat-file.c 541
builtin/check-attr.c 187
builtin/check-ignore.c 188
builtin/check-mailmap.c 67
builtin/check-ref-format.c 89
builtin/checkout-index.c 258
builtin/checkout.c 1286
builtin/clean.c 1001
builtin/clone.c 1113
builtin/column.c 60
builtin/commit-tree.c 130
builtin/commit.c 1830
builtin/config.c 723
builtin/count-objects.c 158
builtin/credential.c 32
builtin/describe.c 483
builtin/diff-files.c 72
builtin/diff-index.c 58
builtin/diff-tree.c 189
builtin/diff.c 474
builtin/fast-export.c 1074
builtin/fetch-pack.c 222
builtin/fetch.c 1241
builtin/fmt-merge-msg.c 715
builtin/for-each-ref.c 82
builtin/fsck.c 695
builtin/gc.c 446
builtin/get-tar-commit-id.c 42
builtin/grep.c 928
builtin/hash-object.c 156
builtin/help.c 501
builtin/index-pack.c 1793
builtin/init-db.c 580
builtin/interpret-trailers.c 50
builtin/log.c 1893
builtin/ls-files.c 568
builtin/ls-remote.c 115
builtin/ls-tree.c 190
builtin/mailinfo.c 62
builtin/mailsplit.c 342
builtin/merge-base.c 260
builtin/merge-file.c 112
builtin/merge-index.c 111
builtin/merge-ours.c 35
builtin/merge-recursive.c 81
builtin/merge-tree.c 380
builtin/merge.c 1640
builtin/mktag.c 175
builtin/mktree.c 192
builtin/mv.c 287
builtin/name-rev.c 414
builtin/notes.c 1022
builtin/pack-objects.c 2780
builtin/pack-redundant.c 696
builtin/pack-refs.c 22
builtin/patch-id.c 199
builtin/prune-packed.c 68
builtin/prune.c 158
builtin/pull.c 929
builtin/push.c 572
builtin/read-tree.c 250
builtin/receive-pack.c 1793
builtin/reflog.c 751
builtin/remote-ext.c 200
builtin/remote-fd.c 80
builtin/remote.c 1634
builtin/repack.c 415
builtin/replace.c 500
builtin/rerere.c 117
builtin/reset.c 390
builtin/rev-list.c 408
builtin/rev-parse.c 877
builtin/revert.c 215
builtin/rm.c 435
builtin/send-pack.c 301
builtin/shortlog.c 342
builtin/show-branch.c 952
builtin/show-ref.c 229
builtin/stripspace.c 62
builtin/submodule--helper.c 875
builtin/symbolic-ref.c 77
builtin/tag.c 498
builtin/unpack-file.c 37
builtin/unpack-objects.c 581
builtin/update-index.c 1166
builtin/update-ref.c 444
builtin/update-server-info.c 26
builtin/upload-archive.c 128
builtin/var.c 94
builtin/verify-commit.c 95
builtin/verify-pack.c 83
builtin/verify-tag.c 59
builtin/worktree.c 478
builtin/write-tree.c 57
bulk-checkin.c 278
bundle.c 494
cache-tree.c 724
color.c 396
column.c 416
combine-diff.c 1544
commit.c 1697
compat/obstack.c 414
compat/terminal.c 148
config.c 2452
connect.c 834
connected.c 117
convert.c 1414
copy.c 68
credential.c 374
csum-file.c 187
ctype.c 67
date.c 1191
decorate.c 86
diff-delta.c 490
diff-lib.c 536
diff-no-index.c 304
diff.c 5157
diffcore-break.c 305
diffcore-delta.c 236
diffcore-order.c 132
diffcore-pickaxe.c 239
diffcore-rename.c 680
dir.c 2708
editor.c 69
entry.c 293
environment.c 348
ewah/bitmap.c 214
ewah/ewah_bitmap.c 711
ewah/ewah_io.c 210
ewah/ewah_rlw.c 116
exec_cmd.c 154
fetch-pack.c 1062
fsck.c 830
gettext.c 180
git.c 719
gpg-interface.c 261
graph.c 1339
grep.c 1822
hashmap.c 266
help.c 480
hex.c 91
ident.c 518
kwset.c 772
levenshtein.c 87
line-log.c 1253
line-range.c 291
list-objects.c 235
ll-merge.c 413
lockfile.c 208
log-tree.c 890
mailinfo.c 1038
mailmap.c 365
match-trees.c 345
merge-blobs.c 93
merge-recursive.c 2109
merge.c 97
mergesort.c 74
name-hash.c 239
notes-cache.c 96
notes-merge.c 752
notes-utils.c 177
notes.c 1319
object.c 428
pack-bitmap-write.c 549
pack-bitmap.c 1069
pack-check.c 182
pack-objects.c 110
pack-revindex.c 201
pack-write.c 372
pager.c 179
parse-options-cb.c 223
parse-options.c 677
patch-delta.c 87
patch-ids.c 106
path.c 1249
pathspec.c 497
pkt-line.c 251
preload-index.c 114
pretty.c 1825
prio-queue.c 91
progress.c 268
prompt.c 76
quote.c 456
reachable.c 207
read-cache.c 2330
ref-filter.c 1713
reflog-walk.c 345
refs.c 1232
refs/files-backend.c 3433
remote.c 2367
replace_object.c 123
rerere.c 1252
resolve-undo.c 193
revision.c 3316
run-command.c 1197
send-pack.c 582
sequencer.c 1164
server-info.c 286
setup.c 1059
sha1-array.c 60
sha1-lookup.c 318
sha1_file.c 3647
sha1_name.c 1515
shallow.c 665
sideband.c 153
sigchain.c 62
split-index.c 322
strbuf.c 866
streaming.c 554
string-list.c 311
submodule-config.c 508
submodule.c 1164
symlinks.c 324
tag.c 196
tempfile.c 306
thread-utils.c 78
trace.c 435
trailer.c 916
transport-helper.c 1388
transport.c 1119
tree-diff.c 718
tree-walk.c 1063
tree.c 254
unpack-trees.c 1961
url.c 132
urlmatch.c 539
usage.c 191
userdiff.c 290
utf8.c 668
varint.c 31
version.c 39
versioncmp.c 144
wildmatch.c 280
worktree.c 306
wrapper.c 699
write_or_die.c 108
ws.c 396
wt-status.c 1756
xdiff-interface.c 321
xdiff/xdiffi.c 645
xdiff/xemit.c 317
xdiff/xhistogram.c 364
xdiff/xmerge.c 687
xdiff/xpatience.c 359
xdiff/xprepare.c 484
xdiff/xutils.c 496
zlib.c 274
EOF

# Writes filelist.out
pkg_write_tus

# man page says output file can be same as input file
sort -o filelist.out filelist.out
ok "translation unit manifest" diff -u filelist.good filelist.out

kill $pid
wait

pkg_clean
