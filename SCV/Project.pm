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
	return $self;
}

sub add_src {
	my ($self, $source) = @_;

	# Write source code to temp directory
	open( my $src_fh, ">", "$self->{tmp_dir}/source.c" );
	syswrite( $src_fh, $source );
	close( $src_fh );
}

sub compile {
	my ($self) = @_;
	my $tmp_dir = $self->{tmp_dir};

	my $makefile = <<EOF;
BIN = program
SRCS = source.c
OBJS = \$(SRCS:c=o)

\$(BIN): \$(OBJS)
	\$(CC) -o \$(BIN) \$(OBJS) \$(LDLIBS)

EOF
	# Write Makefile to temp directory
	open( my $makefile_fh, ">", "$tmp_dir/Makefile" );
	syswrite( $makefile_fh, $makefile );

	# Hook $PATH so we run our "compiler" first
	$ENV{SCV_PATH} = "$ENV{HOME}/src/scv/compilers";
	$ENV{PATH} = "$ENV{SCV_PATH}:$ENV{PATH}";

	# Link in the runtime
	$ENV{CFLAGS} = "-pthread";
	# $ENV{LDLIBS} = "-Lruntime -lruntime -pthread";
	# $ENV{LD_LIBRARY_PATH} = "runtime";

	my $ret = system( "make -C $tmp_dir" );
	die "make failed: $ret\n" if ($ret);
}

sub instrumented_src {
	my ($self) = @_;

	open( my $inst_fh, "<", "$self->{tmp_dir}/inst/source.c" );
	my $inst_src;
	while (my $line = <$inst_fh>) {
		$inst_src .= $line;
	}

	return $inst_src;
}

sub run {
	my ($self, @args) = @_;
	my $tmp_dir = $self->{tmp_dir};

	my $pid = open3(undef, undef, \*CHLD_ERR, "$tmp_dir/program", @args);

	waitpid( $pid, 0 );
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
