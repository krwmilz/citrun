#
# Test that the instrumentation preamble is what we think it is.
#
use Modern::Perl;
use t::utils;
plan tests => 3;


my $inst = Test::Cmd->new( prog => 'bin/citrun_inst', workdir => '' );

$inst->write( "empty.c", "" );
$inst->run( args => "-c empty.c", chdir => $inst->curdir );

my $constructor_decl;
if ($^O eq "MSWin32") {
	$constructor_decl = <<EOF ;
#pragma section("",read)
#define INITIALIZER2_(f,p) \\
	static void f(void); \\
	__declspec(allocate("")) void (*f##_)(void) = f; \\
	__pragma(comment(linker,"")) \\
	static void f(void)
#define INITIALIZER(f) INITIALIZER2_(f,"")
INITIALIZER( init_empty)
{
	citrun_node_add(citrun_major, citrun_minor, &_citrun);
}
EOF
}
else {
	$constructor_decl = <<EOF ;
__attribute__((constructor)) static void
citrun_constructor()
{
	citrun_node_add(citrun_major, citrun_minor, &_citrun);
}
EOF
}

# Known good output.
my $preamble_good = <<EOF ;
#ifdef __cplusplus
extern "" {
#endif

#define CITRUN_PATH_MAX		 256
static const unsigned int	 citrun_major = 0;
static const unsigned int	 citrun_minor = 0;

struct citrun_header {
	char			 magic[4];
	unsigned int		 major;
	unsigned int		 minor;
	unsigned int		 pids[3];
	unsigned int		 units;
	unsigned int		 loc;
	char			 progname[1024];
	char			 cwd[1024];
};

struct citrun_node {
	unsigned int		 size;
	char			 comp_file_path[CITRUN_PATH_MAX];
	char			 abs_file_path[CITRUN_PATH_MAX];
	unsigned long long	*data;
};

void citrun_node_add(unsigned int, unsigned int, struct citrun_node *);
static struct citrun_node _citrun = {
	1,
	"",
	"",
};

$constructor_decl
#ifdef __cplusplus
}
#endif
#line 1
EOF

# Read and sanitize special preamble file created by citrun_inst.
my $preamble;
$inst->read( \$preamble, "empty.c.preamble" );
$preamble =~ s/".*"/""/gm;

eq_or_diff( $preamble,	$preamble_good, 'is preamble identical', { context => 3 } );
is( $inst->stderr,	'',	'is citrun_inst stderr empty' );
is( $? >> 8,		0,	'is citrun_inst exit code 0' );
