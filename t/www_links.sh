#!/bin/sh -u
#
# Test that all html links on the website work.
#
. t/libtap.subr
plan 1

# --spider: don't download the page
# -r: recursive retrieval
# -nd: don't create local dirs
# -nv: turn off extra downloading output
# -H: span accross hosts
# -l: recursion level
ok "is no broken links" wget --spider -r -nd -nv -l 1 http://cit.run
