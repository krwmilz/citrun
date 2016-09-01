#!/bin/sh
#
# Test that citrun run on itself works and the resulting binaries run.
#
. test/package.sh

rm -rf /usr/ports/devel/ccitrunrun
# Port contains some.. "customizations"
cp -R bin/openbsd/ccitrunrun /usr/ports/devel/

plan 14

export NO_CHECKSUM=1
pkg_set "devel/ccitrunrun"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
        26 Source files used as input
         3 Application link commands
        14 Rewrite parse warnings
        26 Rewrite successes
        26 Rewritten source compile successes

Totals:
      5263 Lines of source code
       234 Function definitions
       188 If statements
        26 For loops
         8 While loops
         3 Switch statements
       106 Return statement values
      1007 Call expressions
     16174 Total statements
      1554 Binary operators
         5 Errors rewriting source
EOF
pkg_check

cat <<EOF > filelist.good
src/demo-atlas.cc 149
src/demo-font.cc 253
src/demo-glstate.cc 153
src/demo-shader.cc 210
src/gl_buffer.cc 192
src/gl_view.cc 526
src/glyphy/glyphy-arcs.cc 321
src/glyphy/glyphy-blob.cc 329
src/glyphy/glyphy-extents.cc 90
src/glyphy/glyphy-outline.cc 328
src/glyphy/glyphy-sdf.cc 92
src/glyphy/glyphy-shaders.cc 40
src/matrix4x4.c 399
src/process_dir.cc 42
src/process_file.cc 111
src/shm.cc 60
src/trackball.c 338
EOF

$TEST_WRKDIST/src/ccitrunrun-gl &
pid=$!

sleep 1
pkg_write_tus
sort -o filelist.out filelist.out
ok "ccitrunrun-gl translation unit manifest" diff -u filelist.good filelist.out

kill $pid
wait

ok "rm procfile.shm" rm procfile.shm


cat <<EOF > filelist.good
src/inst_action.cc 118
src/inst_frontend.cc 262
src/inst_log.cc 47
src/inst_main.cc 145
src/inst_visitor.cc 191
EOF

$TEST_WRKDIST/src/ccitrunrun-inst

pkg_write_tus
sort -o filelist.out filelist.out
ok "ccitrunrun-inst translation unit manifest" diff -u filelist.good filelist.out

ok "rm procfile.shm" rm procfile.shm

cat <<EOF > filelist.good
src/process_dir.cc 42
src/process_file.cc 111
src/shm.cc 60
src/term_main.cc 259
EOF

$TEST_WRKDIST/src/ccitrunrun-term

pkg_write_tus
sort -o filelist.out filelist.out
ok "ccitrunrun-term translation unit manifest" diff -u filelist.good filelist.out

pkg_clean
