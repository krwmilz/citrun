use strict;
use warnings;
use Expect;
use Test::More tests => 230 ;
use test::package;
use test::viewer;

my $package = test::package->new("editors/nvi");
my $viewer = test::viewer->new();

my $exp = Expect->spawn("/usr/ports/pobj/nvi-2.1.3/nvi2-2.1.3/build/nvi");
$viewer->accept();
$viewer->cmp_static_data([
	["cl/cl_funcs.c", 853, 192],
	["cl/cl_main.c", 423, 111],
	["cl/cl_read.c", 331, 73],
	["cl/cl_screen.c", 585, 141],
	["cl/cl_term.c", 478, 141],
	["common/conv.c", 471, 61],
	["common/cut.c", 352, 86],
	["common/delete.c", 164, 58],
	["common/encoding.c", 237, 46],
	["common/exf.c", 1525, 356],
	["common/key.c", 871, 149],
	["common/line.c", 658, 146],
	["common/log.c", 768, 141],
	["common/main.c", 608, 129],
	["common/mark.c", 278, 46],
	["common/msg.c", 913, 184],
	["common/options.c", 1189, 226],
	["common/options_f.c", 358, 94],
	["common/put.c", 234, 71],
	["common/recover.c", 974, 315],
	["common/screen.c", 233, 63],
	["common/search.c", 500, 134],
	["common/seq.c", 409, 117],
	["common/util.c", 424, 110],
	["ex/ex.c", 2370, 426],
	["ex/ex_abbrev.c", 114, 53],
	["ex/ex_append.c", 270, 53],
	["ex/ex_args.c", 331, 110],
	["ex/ex_argv.c", 915, 210],
	["ex/ex_at.c", 125, 36],
	["ex/ex_bang.c", 188, 35],
	["ex/ex_cd.c", 132, 39],
	["ex/ex_cmd.c", 446, 6],
	["ex/ex_cscope.c", 1098, 343],
	["ex/ex_delete.c", 65, 17],
	["ex/ex_display.c", 144, 67],
	["ex/ex_edit.c", 160, 41],
	["ex/ex_equal.c", 59, 11],
	["ex/ex_file.c", 83, 17],
	["ex/ex_filter.c", 318, 91],
	["ex/ex_global.c", 317, 89],
	["ex/ex_init.c", 431, 130],
	["ex/ex_join.c", 171, 53],
	["ex/ex_map.c", 119, 54],
	["ex/ex_mark.c", 45, 11],
	["ex/ex_mkexrc.c", 102, 35],
	["ex/ex_move.c", 193, 47],
	["ex/ex_open.c", 46, 11],
	["ex/ex_preserve.c", 105, 30],
	["ex/ex_print.c", 332, 109],
	["ex/ex_put.c", 51, 32],
	["ex/ex_quit.c", 46, 11],
	["ex/ex_read.c", 362, 113],
	["ex/ex_screen.c", 132, 30],
	["ex/ex_script.c", 628, 193],
	["ex/ex_set.c", 46, 12],
	["ex/ex_shell.c", 228, 103],
	["ex/ex_shift.c", 187, 38],
	["ex/ex_source.c", 96, 27],
	["ex/ex_stop.c", 51, 15],
	["ex/ex_subst.c", 1442, 264],
	["ex/ex_tag.c", 1315, 344],
	["ex/ex_txt.c", 426, 80],
	["ex/ex_undo.c", 77, 19],
	["ex/ex_usage.c", 191, 66],
	["ex/ex_util.c", 217, 42],
	["ex/ex_version.c", 40, 8],
	["ex/ex_visual.c", 164, 22],
	["ex/ex_write.c", 376, 125],
	["ex/ex_yank.c", 46, 8],
	["ex/ex_z.c", 146, 26],
	["regex/regcomp.c", 1630, 260],
	["regex/regerror.c", 172, 40],
	["regex/regexec.c", 174, 294],
	["regex/regfree.c", 79, 18],
	["vi/getc.c", 223, 72],
	["vi/v_at.c", 114, 44],
	["vi/v_ch.c", 283, 64],
	["vi/v_cmd.c", 506, 6],
	["vi/v_delete.c", 106, 27],
	["vi/v_ex.c", 651, 155],
	["vi/v_increment.c", 265, 82],
	["vi/v_init.c", 130, 40],
	["vi/v_itxt.c", 515, 141],
	["vi/v_left.c", 284, 42],
	["vi/v_mark.c", 232, 47],
	["vi/v_match.c", 178, 75],
	["vi/v_paragraph.c", 341, 62],
	["vi/v_put.c", 141, 21],
	["vi/v_redraw.c", 38, 8],
	["vi/v_replace.c", 203, 74],
	["vi/v_right.c", 142, 34],
	["vi/v_screen.c", 64, 11],
	["vi/v_scroll.c", 448, 76],
	["vi/v_search.c", 549, 116],
	["vi/v_section.c", 251, 48],
	["vi/v_sentence.c", 356, 128],
	["vi/v_status.c", 39, 8],
	["vi/v_txt.c", 2923, 489],
	["vi/v_ulcase.c", 172, 53],
	["vi/v_undo.c", 136, 16],
	["vi/v_util.c", 168, 60],
	["vi/v_word.c", 527, 181],
	["vi/v_xchar.c", 104, 28],
	["vi/v_yank.c", 81, 15],
	["vi/v_z.c", 146, 51],
	["vi/v_zexit.c", 53, 15],
	["vi/vi.c", 1247, 215],
	["vi/vs_line.c", 539, 79],
	["vi/vs_msg.c", 901, 204],
	["vi/vs_refresh.c", 887, 190],
	["vi/vs_relative.c", 295, 49],
	["vi/vs_smap.c", 1243, 379],
	["vi/vs_split.c", 950, 172],
]);

# Check that at least something has executed.
$viewer->cmp_dynamic_data();

$exp->hard_close();
$viewer->close();

open( my $fh, ">", "check.good" );
print $fh <<EOF;
Summary:
         2 Log files found
       116 Calls to the rewrite tool
       115 Source files used as input
         2 Application link commands
        32 Rewrite parse warnings
       115 Rewrite successes
       115 Rewritten source compile successes

Totals:
     47830 Lines of source code
         2 Functions called 'main'
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

system("$ENV{CITRUN_TOOLS}/citrun-check /usr/ports/pobj/nvi-* > check.out");
system("diff -u check.good check.out");
$package->clean();
