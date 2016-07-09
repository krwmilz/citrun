package Test::Package;
use strict;

use Cwd;
use IPC::Open2;
use File::Temp qw( tempdir );

sub new {
	my ($class, $dist_name, $dist_root, $extract_cmd) = @_;

	my $self = {};
	bless($self, $class);

	# Always set this so we never try to connect to a real viewer.
	$ENV{CITRUN_SOCKET} = getcwd . "/citrun-test.socket";

	return $self if (! defined ($dist_name));
	$self->{dist_name} = $dist_name;

	# Create temporary directory for the contents of this package.
	my $dir = tempdir( CLEANUP => 1 );
	$self->{dir} = $dir;

	mkdir "tt/distfiles";
	if (! -e "tt/distfiles/$dist_name") {
		my $dist_url = "$dist_root$dist_name";
		system("curl $dist_url -o tt/distfiles/$dist_name") == 0 or die "download failed";
	}

	my $abs_dist_path = getcwd . "/tt/distfiles/$dist_name";
	system("cd $dir && $extract_cmd $abs_dist_path") == 0 or die "extract failed";

	return $self;
}

sub set_srcdir {
	my ($self, $srcdir) = @_;
	$self->{srcdir} = $self->{dir} . $srcdir;
	return $self->{srcdir};
};

sub dependencies {
	my ($self, @deps) = @_;

	my @installed_pkgs;
	@installed_pkgs = parse_output('pkg_info', '-q') if ($^O eq "openbsd");
	@installed_pkgs = parse_output('port', 'installed') if ($^O eq "darwin");
	@installed_pkgs = parse_output('apt-mark', 'showmanual') if ($^O eq "linux");

	my @missing_deps;
	for my $dep (@deps) {
		my $found = 0;

		for (@installed_pkgs) {
			if (/^\s*$dep.*$/) {
				$found = 1;
				last;
			}
		}
		if ($found == 0) {
			push @missing_deps, $dep;
		}
	}

	if (@missing_deps) {
		die "Missing dependencies: '" . join(' ', @missing_deps) . "'\n";
	}
}

sub parse_output {
	my $pid = open2(\*CHLD_OUT, undef, @_);

	waitpid( $pid, 0 );
	my $pkg_info_exit_code = $? >> 8;

	my @pkgs;
	push @pkgs, ($_) while (readline \*CHLD_OUT);
	return @pkgs;
}

sub patch {
	my ($self, $patch_cmd) = @_;
	system("cd $self->{srcdir} && $patch_cmd") == 0 or die "patching failed";
}

sub get_file_size {
	my ($self, $file) = @_;

	die "file '$file' does not exist." unless (-f "$self->{srcdir}$file");
	return ((stat "$self->{srcdir}$file")[7]);
}

sub clean {
	my ($self, $clean_cmd) = @_;

	$self->{clean_cmd} = $clean_cmd;
	$self->time_system($clean_cmd);
}

sub configure {
	my ($self, $config_cmd) = @_;

	$self->{config_cmd} = $config_cmd;
	return $self->time_system($config_cmd);
}

sub compile {
	my ($self, $compile_cmd) = @_;

	$self->{compile_cmd} = $compile_cmd;
	return $self->time_system($compile_cmd);
}

sub inst_configure {
	my ($self) = @_;

	die "configure() was not called" unless (exists $self->{config_cmd});
	return $self->time_system("citrun-wrap $self->{config_cmd}");
}

sub inst_compile {
	my ($self) = @_;

	die "compile() was not called" unless (exists $self->{compile_cmd});
	return $self->time_system("citrun-wrap $self->{compile_cmd}");
}

sub time_system {
	my ($self, $cmd) = @_;

	my $start = time;
	system("cd $self->{srcdir} && $cmd") == 0 or die "'$cmd'\n";
	return time - $start;
}

1;
