package test::package;
use strict;

use Cwd;
use IPC::Open2;
use File::Temp qw( tempdir );

sub new {
	my ($class, $name) = @_;

	my $self = {};
	bless($self, $class);

	$self->{port} = "/usr/ports/$name";
	my $dir = tempdir( CLEANUP => 1 );
	$ENV{CITRUN_SOCKET} = "test.socket";
	$ENV{CITRUN_TOOLS} = cwd . "/src";
	chdir $dir;

	system(<<EOF) == 0 or die "build failed.";
set -e
make -C $self->{port} full-build-depends | sort | uniq > deps
pkg_info -q > installed
comm -2 -3 deps installed > needed
diff -u /dev/null needed

make -C $self->{port} clean=all
make -C $self->{port} PORTPATH="$ENV{CITRUN_TOOLS}:\\\${WRKDIR}/bin:\$PATH"
EOF
	return $self;
}

sub clean {
	my ($self) = @_;
	#system("citrun-check /usr/ports/pobj/$self->{port}-*");
	system("make -C $self->{port} clean=all") == 0 or die "$!";
}

1;
