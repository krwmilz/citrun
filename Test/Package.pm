package Test::Package;
use strict;

use IPC::Open2;
use File::Temp qw( tempdir );

sub new {
	my ($class, $dist_name, $dist_root, $extract_cmd) = @_;

	my $self = {};
	bless($self, $class);

	# Create temporary directory for the contents of this package.
	my $dir = tempdir( CLEANUP => 1 );
	$self->{dir} = $dir;

	my $dist_url = "$dist_root$dist_name";
	system("cd $dir && curl -O $dist_url") == 0 or die "download failed";
	system("cd $dir && $extract_cmd $dist_name") == 0 or die "extract failed";

	return $self;
}

sub dir {
	my ($self) = @_;
	return $self->{dir};
}

sub dependencies {
	my ($self, @deps) = @_;

	my @installed_pkgs;
	@installed_pkgs = parse_output('pkg_info', '-q') if ($^O eq "openbsd");
	@installed_pkgs = parse_output('port', 'installed') if ($^O eq "darwin");

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

1;
