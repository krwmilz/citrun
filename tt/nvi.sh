#!/bin/sh
#
# Tests that nvi works with C It Run.
#
. test/package.sh
plan 10

pkg_set "editors/nvi"
pkg_check_deps
pkg_clean
pkg_build

cat <<EOF > check.good
Summary:
       115 Source files used as input
         2 Application link commands
        32 Rewrite parse warnings
       115 Rewrite successes
       115 Rewritten source compile successes

Totals:
     47830 Lines of source code
       658 Function definitions
      1711 If statements
       176 For loops
        33 While loops
         6 Do while loops
       100 Switch statements
       979 Return statement values
      1646 Call expressions
     49384 Total statements
      4008 Binary operators
       353 Errors rewriting source
EOF
pkg_check

cat <<EOF > filelist.good
/cl/cl_funcs.c 853
/cl/cl_main.c 423
/cl/cl_read.c 331
/cl/cl_screen.c 585
/cl/cl_term.c 478
/common/conv.c 471
/common/cut.c 352
/common/delete.c 164
/common/encoding.c 237
/common/exf.c 1525
/common/key.c 871
/common/line.c 658
/common/log.c 768
/common/main.c 608
/common/mark.c 278
/common/msg.c 913
/common/options.c 1189
/common/options_f.c 358
/common/put.c 234
/common/recover.c 974
/common/screen.c 233
/common/search.c 500
/common/seq.c 409
/common/util.c 424
/ex/ex.c 2370
/ex/ex_abbrev.c 114
/ex/ex_append.c 270
/ex/ex_args.c 331
/ex/ex_argv.c 915
/ex/ex_at.c 125
/ex/ex_bang.c 188
/ex/ex_cd.c 132
/ex/ex_cmd.c 446
/ex/ex_cscope.c 1098
/ex/ex_delete.c 65
/ex/ex_display.c 144
/ex/ex_edit.c 160
/ex/ex_equal.c 59
/ex/ex_file.c 83
/ex/ex_filter.c 318
/ex/ex_global.c 317
/ex/ex_init.c 431
/ex/ex_join.c 171
/ex/ex_map.c 119
/ex/ex_mark.c 45
/ex/ex_mkexrc.c 102
/ex/ex_move.c 193
/ex/ex_open.c 46
/ex/ex_preserve.c 105
/ex/ex_print.c 332
/ex/ex_put.c 51
/ex/ex_quit.c 46
/ex/ex_read.c 362
/ex/ex_screen.c 132
/ex/ex_script.c 628
/ex/ex_set.c 46
/ex/ex_shell.c 228
/ex/ex_shift.c 187
/ex/ex_source.c 96
/ex/ex_stop.c 51
/ex/ex_subst.c 1442
/ex/ex_tag.c 1315
/ex/ex_txt.c 426
/ex/ex_undo.c 77
/ex/ex_usage.c 191
/ex/ex_util.c 217
/ex/ex_version.c 40
/ex/ex_visual.c 164
/ex/ex_write.c 376
/ex/ex_yank.c 46
/ex/ex_z.c 146
/regex/regcomp.c 1630
/regex/regerror.c 172
/regex/regexec.c 174
/regex/regfree.c 79
/vi/getc.c 223
/vi/v_at.c 114
/vi/v_ch.c 283
/vi/v_cmd.c 506
/vi/v_delete.c 106
/vi/v_ex.c 651
/vi/v_increment.c 265
/vi/v_init.c 130
/vi/v_itxt.c 515
/vi/v_left.c 284
/vi/v_mark.c 232
/vi/v_match.c 178
/vi/v_paragraph.c 341
/vi/v_put.c 141
/vi/v_redraw.c 38
/vi/v_replace.c 203
/vi/v_right.c 142
/vi/v_screen.c 64
/vi/v_scroll.c 448
/vi/v_search.c 549
/vi/v_section.c 251
/vi/v_sentence.c 356
/vi/v_status.c 39
/vi/v_txt.c 2923
/vi/v_ulcase.c 172
/vi/v_undo.c 136
/vi/v_util.c 168
/vi/v_word.c 527
/vi/v_xchar.c 104
/vi/v_yank.c 81
/vi/v_z.c 146
/vi/v_zexit.c 53
/vi/vi.c 1247
/vi/vs_line.c 539
/vi/vs_msg.c 901
/vi/vs_refresh.c 887
/vi/vs_relative.c 295
/vi/vs_smap.c 1243
/vi/vs_split.c 950
EOF

$TEST_WRKDIST/build/nvi > out

pkg_write_tus

# nvi ends up using absolute paths to source files when compiling.
ok "strip tu paths" sed -i -e "s,/usr/ports/pobj/nvi-[0-9.]*/nvi2-[0-9.]*,," filelist.out
ok "sorting" sort -o filelist.out filelist.out
ok "translation unit manifest" diff -u filelist.good filelist.out

pkg_clean
