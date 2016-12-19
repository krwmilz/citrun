#!/bin/sh -u
#
# Check that the advertised source file extensions work.
#
. t/utils.subr
plan 8


touch main.{c,cc,cxx,cpp,C}
ok "extension .c" citrun-wrap cc -c main.c
ok "extension .cc" citrun-wrap c++ -c main.cc
ok "extension .cxx" citrun-wrap c++ -c main.cxx
ok "extension .cpp" citrun-wrap c++ -c main.cpp
ok "extension .C (not supported)" citrun-wrap c++ -c main.C

cat <<EOF > check.good
Summary:
         4 Source files used as input
         4 Rewrite successes
         4 Rewritten source compile successes

Totals:
         4 Lines of source code
EOF

ok "citrun-check" citrun-check -o check.out
strip_millis check.out
ok "citrun-check diff" diff -u check.good check.out
