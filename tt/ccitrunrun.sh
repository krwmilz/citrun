#!/bin/sh -u
#
# Test that citrun run on itself works and the resulting binaries run.
#
if [ `uname` = "OpenBSD" ]; then
	rm -rf /usr/ports/devel/ccitrunrun
	cp -R distrib/openbsd/ccitrunrun /usr/ports/devel/
fi

. tt/package.subr "devel/ccitrunrun"
plan 13

enter_tmpdir

export NO_CHECKSUM=1
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
        24 Source files used as input
         2 Application link commands
        14 Rewrite parse warnings
        24 Rewrite successes
        23 Rewritten source compile successes
         1 Rewritten source compile failures

Totals:
      4907 Lines of source code
       222 Function definitions
       179 If statements
        24 For loops
         5 While loops
         3 Switch statements
       100 Return statement values
       985 Call expressions
     15568 Total statements
      1475 Binary operators
         5 Errors rewriting source
EOF
pkg_check

cat <<EOF > tu_list.good
src/demo-atlas.cc 149
src/demo-font.cc 253
src/demo-glstate.cc 153
src/demo-shader.cc 210
src/gl_buffer.cc 192
src/gl_main.cc 216
src/gl_view.cc 526
src/glyphy/glyphy-arcs.cc 321
src/glyphy/glyphy-blob.cc 329
src/glyphy/glyphy-extents.cc 90
src/glyphy/glyphy-outline.cc 328
src/glyphy/glyphy-sdf.cc 92
src/glyphy/glyphy-shaders.cc 40
src/matrix4x4.c 399
src/process_dir.cc 47
src/process_file.cc 177
src/trackball.c 338
EOF

$workdir/src/ccitrunrun-gl < /dev/null

ok "is write_tus.pl exit code 0" \
	perl -I$treedir $treedir/tt/write_tus.pl ${CITRUN_PROCDIR}ccitrunrun-gl_*
pkg_check_manifest

cat <<EOF > tu_list.good
src/inst_action.cc 118
src/inst_frontend.cc 262
src/inst_log.cc 47
src/inst_main.cc 145
src/inst_visitor.cc 188
EOF

$workdir/src/ccitrunrun-inst

ok "is write_tus.pl exit code 0" \
	perl -I$treedir $treedir/tt/write_tus.pl ${CITRUN_PROCDIR}ccitrunrun-inst*
pkg_check_manifest

pkg_clean
