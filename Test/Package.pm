package Test::Package;
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

	$self->{portsdir} = "/usr/ports";
	$self->{port} = "$self->{portsdir}/$name";

	$ENV{CITRUN_SOCKET} = $self->{dir} . "/test.socket";

	return $self;
}

sub depends {
	my ($self) = @_;

	system("make -C $self->{port} full-build-depends > $self->{dir}/deps") == 0
		or die "$!";
	system("doas pkg_add -zl $self->{dir}/deps") == 0 or die "$!";
}

sub clean {
	my ($self) = @_;

	system("make -C $self->{port} clean=all") == 0 or die "$!";
}

sub build {
	my ($self) = @_;

	system("make -C $self->{port} PORTPATH=\"/home/kyle/citrun/src:\\\${WRKDIR}/bin:\$PATH\"") == 0
		or die "$!";
}

sub get_file_size {
	my ($self, $file) = @_;

	die "file '$file' does not exist." unless (-f "$self->{srcdir}$file");
	return ((stat "$self->{srcdir}$file")[7]);
}

sub time_system {
	my ($self, $cmd) = @_;

	my $start = time;
	system("cd $self->{srcdir} && $cmd") == 0 or die "'$cmd'\n";
	return time - $start;
}

1;
