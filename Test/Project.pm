package Test::Project;
use strict;

use Cwd;
use File::Temp qw( tempdir );
use Test;
use IPC::Open2;

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	# Make new temporary directory, clean it up at exit
	$self->{tmp_dir} = tempdir( CLEANUP => 1 );
	$self->{src_files} = [];
	$self->{prog_name} = "program";
	return $self;
}

sub add_src {
	my ($self, $source) = @_;
	my $num_src_files = scalar(@{ $self->{src_files} });

	# Create temporary file name
	my $src_name = "source_$num_src_files.c";

	# Write source code to temp directory
	open( my $src_fh, ">", "$self->{tmp_dir}/$src_name" );
	syswrite( $src_fh, $source );
	close( $src_fh );

	push @{ $self->{src_files} }, $src_name;
}

sub compile {
	my ($self) = @_;
	my $tmp_dir = $self->{tmp_dir};
	my $src_files = join(" ", @{ $self->{src_files} });

	my $jamfile = <<EOF;
Main $self->{prog_name} : $src_files ;
EOF
	# Write Jamfile to temp directory
	open( my $jamfile_fh, ">", "$tmp_dir/Jamfile" );
	syswrite( $jamfile_fh, $jamfile );
	close( $jamfile_fh );

	# Use the tools in this source tree
	$ENV{PATH} = cwd . "/src:$ENV{PATH}";

	my $ret = system( "cd $tmp_dir && jam" );
	die "jam failed: $ret\n" if ($ret);
}

sub run {
	my ($self, @args) = @_;

	my $tmp_dir = $self->{tmp_dir};
	$self->{pid} = open2(\*CHLD_OUT, undef, "$tmp_dir/$self->{prog_name}", @args);
}

sub kill {
	my ($self) = @_;
	kill 'TERM', $self->{pid};
}

sub wait {
	my ($self) = @_;

	waitpid( $self->{pid}, 0 );
	my $real_ret = $? >> 8;

	my $stderr;
	while (my $line = <CHLD_OUT>) {
		$stderr .= $line;
	}

	return ($real_ret, $stderr);
}

sub tmpdir {
	my ($self) = @_;

	return "/private$self->{tmp_dir}" if ($^O eq 'darwin');
	return $self->{tmp_dir};
}

sub DESTROY {
	my ($self) = @_;

	$self->kill() if ($self->{pid});
}

1;
