package SCV::Project;
use strict;

use File::Temp qw( tempdir );
use Test;
use IPC::Open3;

sub new {
	my ($class, $tmp_dir) = @_;
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
BIN = program
SRCS = $src_files
OBJS = \$(SRCS:c=o)

\$(BIN): \$(OBJS)
	\$(CC) -o \$(BIN) \$(OBJS) \$(LDLIBS)

EOF
	# Write Makefile to temp directory
	open( my $makefile_fh, ">", "$tmp_dir/Makefile" );
	syswrite( $makefile_fh, $makefile );

	# Hook $PATH so we run our "compiler" first
	$ENV{SCV_PATH} = "$ENV{HOME}/src/scv/instrument/compilers";
	$ENV{PATH} = "$ENV{SCV_PATH}:$ENV{PATH}";

	# Link in the runtime
	$ENV{CFLAGS} = "-pthread -I/home/kyle/src/scv/include";
	$ENV{LDLIBS} = "-L/home/kyle/src/scv/lib -lscv -pthread";
	$ENV{LD_LIBRARY_PATH} = "lib";

	my $ret = system( "make -C $tmp_dir" );
	die "make failed: $ret\n" if ($ret);
}

sub instrumented_src {
	my ($self) = @_;

	open( my $inst_fh, "<", "$self->{tmp_dir}/inst/source_0.c" );
	my $inst_src;
	while (my $line = <$inst_fh>) {
		$inst_src .= $line;
	}

	return $inst_src;
}

sub run {
	my ($self, @args) = @_;

	my $tmp_dir = $self->{tmp_dir};
	$self->{pid} = open3(undef, undef, \*CHLD_ERR, "$tmp_dir/program", @args);
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
	return $self->{tmp_dir};
}

1;
