#!/bin/sh -e
#
# Instruments git, checks logs, and makes sure the resulting program still
# works.
#
echo 1..5
. test/package.sh

pkg_instrument "devel/git"

cat <<EOF > check.good
Summary:
       448 Calls to the rewrite tool
       381 Source files used as input
        82 Application link commands
        45 Rewrite parse warnings
         5 Rewrite parse errors
       376 Rewrite successes
         5 Rewrite failures (False Positive)
       374 Rewritten source compile successes
         2 Rewritten source compile failures (False Positive)

Totals:
    185689 Lines of source code
       100 Functions called 'main'
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
pkg_check 4

# Start git doing something that will take a while. At my own expense.
$TEST_WRKDIST/git clone http://git.0x30.net/citrun citrun_TEST_CLONE &

echo ok 5 - started git clone

cat <<EOF> dump.good
abspath.c
advice.c
alias.c
alloc.c
archive-tar.c
archive-zip.c
archive.c
argv-array.c
attr.c
base85.c
bisect.c
blob.c
branch.c
builtin/add.c
builtin/am.c
builtin/annotate.c
builtin/apply.c
builtin/archive.c
builtin/bisect--helper.c
builtin/blame.c
builtin/branch.c
builtin/bundle.c
builtin/cat-file.c
builtin/check-attr.c
builtin/check-ignore.c
builtin/check-mailmap.c
builtin/check-ref-format.c
builtin/checkout-index.c
builtin/checkout.c
builtin/clean.c
builtin/clone.c
builtin/column.c
builtin/commit-tree.c
builtin/commit.c
builtin/config.c
builtin/count-objects.c
builtin/credential.c
builtin/describe.c
builtin/diff-files.c
builtin/diff-index.c
builtin/diff-tree.c
builtin/diff.c
builtin/fast-export.c
builtin/fetch-pack.c
builtin/fetch.c
builtin/fmt-merge-msg.c
builtin/for-each-ref.c
builtin/fsck.c
builtin/gc.c
builtin/get-tar-commit-id.c
builtin/grep.c
builtin/hash-object.c
builtin/help.c
builtin/index-pack.c
builtin/init-db.c
builtin/interpret-trailers.c
builtin/log.c
builtin/ls-files.c
builtin/ls-remote.c
builtin/ls-tree.c
builtin/mailinfo.c
builtin/mailsplit.c
builtin/merge-base.c
builtin/merge-file.c
builtin/merge-index.c
builtin/merge-ours.c
builtin/merge-recursive.c
builtin/merge-tree.c
builtin/merge.c
builtin/mktag.c
builtin/mktree.c
builtin/mv.c
builtin/name-rev.c
builtin/notes.c
builtin/pack-objects.c
builtin/pack-redundant.c
builtin/pack-refs.c
builtin/patch-id.c
builtin/prune-packed.c
builtin/prune.c
builtin/pull.c
builtin/push.c
builtin/read-tree.c
builtin/receive-pack.c
builtin/reflog.c
builtin/remote-ext.c
builtin/remote-fd.c
builtin/remote.c
builtin/repack.c
builtin/replace.c
builtin/rerere.c
builtin/reset.c
builtin/rev-list.c
builtin/rev-parse.c
builtin/revert.c
builtin/rm.c
builtin/send-pack.c
builtin/shortlog.c
builtin/show-branch.c
builtin/show-ref.c
builtin/stripspace.c
builtin/submodule--helper.c
builtin/symbolic-ref.c
builtin/tag.c
builtin/unpack-file.c
builtin/unpack-objects.c
builtin/update-index.c
builtin/update-ref.c
builtin/update-server-info.c
builtin/upload-archive.c
builtin/var.c
builtin/verify-commit.c
builtin/verify-pack.c
builtin/verify-tag.c
builtin/worktree.c
builtin/write-tree.c
bulk-checkin.c
bundle.c
cache-tree.c
color.c
column.c
combine-diff.c
commit.c
compat/obstack.c
compat/terminal.c
config.c
connect.c
connected.c
convert.c
copy.c
credential.c
csum-file.c
ctype.c
date.c
decorate.c
diff-delta.c
diff-lib.c
diff-no-index.c
diff.c
diffcore-break.c
diffcore-delta.c
diffcore-order.c
diffcore-pickaxe.c
diffcore-rename.c
dir.c
editor.c
entry.c
environment.c
ewah/bitmap.c
ewah/ewah_bitmap.c
ewah/ewah_io.c
ewah/ewah_rlw.c
exec_cmd.c
fetch-pack.c
fsck.c
gettext.c
git.c
gpg-interface.c
graph.c
grep.c
hashmap.c
help.c
hex.c
ident.c
kwset.c
levenshtein.c
line-log.c
line-range.c
list-objects.c
ll-merge.c
lockfile.c
log-tree.c
mailinfo.c
mailmap.c
match-trees.c
merge-blobs.c
merge-recursive.c
merge.c
mergesort.c
name-hash.c
notes-cache.c
notes-merge.c
notes-utils.c
notes.c
object.c
pack-bitmap-write.c
pack-bitmap.c
pack-check.c
pack-objects.c
pack-revindex.c
pack-write.c
pager.c
parse-options-cb.c
parse-options.c
patch-delta.c
patch-ids.c
path.c
pathspec.c
pkt-line.c
preload-index.c
pretty.c
prio-queue.c
progress.c
prompt.c
quote.c
reachable.c
read-cache.c
ref-filter.c
reflog-walk.c
refs.c
refs/files-backend.c
remote.c
replace_object.c
rerere.c
resolve-undo.c
revision.c
run-command.c
send-pack.c
sequencer.c
server-info.c
setup.c
sha1-array.c
sha1-lookup.c
sha1_file.c
sha1_name.c
shallow.c
sideband.c
sigchain.c
split-index.c
strbuf.c
streaming.c
string-list.c
submodule-config.c
submodule.c
symlinks.c
tag.c
tempfile.c
thread-utils.c
trace.c
trailer.c
transport-helper.c
transport.c
tree-diff.c
tree-walk.c
tree.c
unpack-trees.c
url.c
urlmatch.c
usage.c
userdiff.c
utf8.c
varint.c
version.c
versioncmp.c
wildmatch.c
worktree.c
wrapper.c
write_or_die.c
ws.c
wt-status.c
xdiff-interface.c
xdiff/xdiffi.c
xdiff/xemit.c
xdiff/xhistogram.c
xdiff/xmerge.c
xdiff/xpatience.c
xdiff/xprepare.c
xdiff/xutils.c
zlib.c
EOF

$TEST_TOOLS/citrun-dump -f | sort > dump.out
test_diff 6 "citrun-dump diff" dump.out dump.good

pkg_clean
