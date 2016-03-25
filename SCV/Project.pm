package SCV::Project;
use strict;

use Cwd;
use File::Temp qw( tempdir );
use Test;
use IPC::Open3;

sub new {
	my ($class) = @_;
	my $self = {};
	bless ($self, $class);

	# Make new temporary directory, clean it up at exit
	$self->{tmp_dir} = tempdir( CLEANUP => 1 );
	$self->{src_files} = [];
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

	my $makefile = <<EOF;
PROG = program
SRCS = $src_files
MAN =

.include <bsd.prog.mk>
EOF
	# Write Makefile to temp directory
	open( my $makefile_fh, ">", "$tmp_dir/Makefile" );
	syswrite( $makefile_fh, $makefile );

	# Use the wrapper to make sure it works
	my $ret = system( "wrap/scv_wrap make -C $tmp_dir" );
	die "make failed: $ret\n" if ($ret);
}

sub instrumented_src {
	my ($self) = @_;

	open( my $inst_fh, "<", "$self->{tmp_dir}/inst/source_0.c" );

	# Knock off the instrumentation preamble
	my $line = <$inst_fh> for (1..19);

	my $inst_src;
	while (my $line = <$inst_fh>) {
		$inst_src .= $line;
	}
	return $inst_src;
}

sub run {
	my ($self, @args) = @_;

	$ENV{SCV_VIEWER_SOCKET} = "SCV::Viewer.socket";

	my $tmp_dir = $self->{tmp_dir};
	$self->{pid} = open3(undef, undef, \*CHLD_ERR, "wrap/scv_wrap", "$tmp_dir/program", @args);
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
	while (my $line = <CHLD_ERR>) {
		$stderr .= $line;
	}

	return ($real_ret, $stderr);
}

sub get_tmpdir {
	my ($self) = @_;

	return "/private$self->{tmp_dir}" if ($^O eq 'darwin');

	return $self->{tmp_dir};
}

1;
