package test::package;
use strict;

use Cwd;
use IPC::Open2;
use File::Temp qw( tempdir );

sub new {
	my ($class, $name) = @_;

	my $self = {};
	bless($self, $class);

	my $dir = tempdir( CLEANUP => 1 );
	$self->{dir} = $dir;

	$self->{port} = "/usr/ports/$name";

	$ENV{CITRUN_SOCKET} = $self->{dir} . "/test.socket";
	my $cwd = cwd;

	system(<<EOF) == 0 or die "build failed.";
set -e
make -C $self->{port} full-build-depends > $self->{dir}/deps
doas pkg_add -zl $self->{dir}/deps

make -C $self->{port} clean=all
make -C $self->{port} PORTPATH="$cwd/src:\\\${WRKDIR}/bin:\$PATH"
EOF

	return $self;
}

sub clean {
	my ($self) = @_;
	#system("citrun-check /usr/ports/pobj/$self->{port}-*");
	system("make -C $self->{port} clean=all") == 0 or die "$!";
}

1;
