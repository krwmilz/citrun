use strict;
use warnings;
use Cwd;
use Expect;
use Test::More tests => 49;
use test::package;
use test::viewer;

$ENV{NO_CHECKSUM} = 1;
system("rm -rf /usr/ports/devel/ccitrunrun; cp -R bin/openbsd/ccitrunrun /usr/ports/devel/");
my $package = test::package->new("devel/ccitrunrun");
my $viewer = test::viewer->new();

system("./src/citrun-check /usr/ports/pobj/ccitrunrun-*");

my $exp = Expect->spawn("/usr/ports/pobj/ccitrunrun-*/citrun-*/src/ccitrunrun-gl");
$viewer->accept();
$viewer->cmp_static_data([
	# file name			lines	instrumented sites
	["/src/af_unix.cc",		166,	4207],
	["/src/demo-atlas.cc",		149,	2045],
	["/src/demo-font.cc",		253,	5954],
	["/src/demo-glstate.cc",	153,	2040],
	["/src/demo-shader.cc",		210,	2162],
	["/src/gl_buffer.cc",		192,	2077],
	["/src/gl_main.cc",		269,	6810],
	["/src/gl_view.cc",		526,	2160],
	["/src/glyphy/glyphy-arcs.cc",	321,	16125],
	["/src/glyphy/glyphy-blob.cc",	329,	16090],
	["/src/glyphy/glyphy-extents.cc",90,	15190],
	["/src/glyphy/glyphy-outline.cc",328,	15663],
	["/src/glyphy/glyphy-sdf.cc",	92,	15618],
	["/src/glyphy/glyphy-shaders.cc",40,	15168],
	["/src/matrix4x4.c",		399,	191],
	["/src/runtime_proc.cc",	89,	6905],
	["/src/trackball.c",		338,	46],
]);
$exp->hard_close();
$viewer->close();

$exp = Expect->spawn("/usr/ports/pobj/ccitrunrun-*/citrun-*/src/ccitrunrun-term");
$viewer->accept();
$viewer->cmp_static_data([
	# file name		lines	instrumented sites
	["/src/af_unix.cc",	166,	4207],
	["/src/runtime_proc.cc", 89,	6905],
	["/src/term_main.cc",	264,	7658],
]);
$exp->hard_close();
$viewer->close();

$exp = Expect->spawn("/usr/ports/pobj/ccitrunrun-*/citrun-*/src/ccitrunrun-inst");
$viewer->accept();

$viewer->cmp_static_data([
	# file name			lines	instrumented sites
	[ "/src/inst_action.cc",	128,	63901 ],
	[ "/src/inst_main.cc",		398,	64187 ],
	[ "/src/inst_visitor.cc",	150,	54839 ],
]);

$exp->hard_close();

open( my $fh, ">", "check.good" );
print $fh <<EOF;
Checking ..done

Summary:
         1 Log files found
        23 Source files input
        26 Calls to the instrumentation tool
        23 Forked compilers
        23 Instrument successes
         3 Application link commands
        10 Warnings during source parsing

Totals:
      5350 Lines of source code
       736 Lines of instrumentation header
         3 Functions called 'main'
       222 Function definitions
       205 If statements
        27 For loops
        12 While loops
         3 Switch statements
        89 Return statement values
      1097 Call expressions
     16820 Total statements
         6 Errors rewriting source
EOF

system("$ENV{CITRUN_TOOLS}/citrun-check /usr/ports/pobj/ccitrunrun-* > check.out");
system("diff -u check.good check.out");
$package->clean();
