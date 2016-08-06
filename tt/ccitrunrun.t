use strict;
use warnings;
use Cwd;
use Expect;
use Test::More tests => 95;
use Test::Package;
use Test::Viewer;

$ENV{NO_CHECKSUM} = 1;
system("rm -rf /usr/ports/devel/ccitrunrun; cp -R bin/openbsd/ccitrunrun /usr/ports/devel/");
my $package = Test::Package->new("devel/ccitrunrun");
my $viewer = Test::Viewer->new();

system("citrun-check /usr/ports/pobj/ccitrunrun-*");

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
	["/src/runtime.cc",		89,	6905],
	["/src/trackball.c",		338,	46],
]);
$exp->hard_close();
$viewer->close();

$exp = Expect->spawn("/usr/ports/pobj/ccitrunrun-*/citrun-*/src/ccitrunrun-term");
$viewer->accept();
$viewer->cmp_static_data([
	# file name		lines	instrumented sites
	["/src/af_unix.cc",	166,	4207],
	["/src/runtime.cc",	89,	6905],
	["/src/term_main.cc",	265,	7658],
]);
$exp->hard_close();
$viewer->close();

$exp = Expect->spawn("/usr/ports/pobj/ccitrunrun-*/citrun-*/src/ccitrunrun-inst");
$viewer->accept();

$viewer->cmp_static_data([
	# file name			lines	instrumented sites
	[ "/src/inst_action.cc",	84,	63901 ],
	[ "/src/inst_ast_visitor.cc",	112,	54839 ],
	[ "/src/inst_main.cc",		396,	64187 ],
]);

$exp->hard_close();
#$package->clean();
