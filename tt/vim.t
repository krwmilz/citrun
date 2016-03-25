use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 7;

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();

my $tmpdir = $project->get_tmpdir();

my $vim_src = "ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2";
is( system("cd $tmpdir && curl -O $vim_src"), 0, "download" );
is( system("cd $tmpdir && tar xjf vim-7.4.tar.bz2"), 0, "extract" );

my $scv_wrap = "wrap/scv_wrap";
is( system("$scv_wrap make -C $tmpdir/vim74/src scratch"), 0, "make scratch" );
is( system("$scv_wrap make -C $tmpdir/vim74/src config LIBS=-lscv"), 0, "make config" );
is( system("rm $tmpdir/vim74/src/SRC_NUMBER"), 0, "rm SRC_NUMBER" );
system("$scv_wrap make -C $tmpdir/vim74/src myself");

# Launch the newly compiled programs and make sure the runtime is communicating
$project->{prog_name} = "vim74/src/vim";
$project->run();

$viewer->accept();

my $runtime_metadata = $viewer->get_metadata();
is( $runtime_metadata->{num_tus}, 55, "translation unit count" );
# is( $runtime_metadata->{pid}, 5, "" );
# is( $runtime_metadata->{ppid}, 5, "" );
# is( $runtime_metadata->{pgrp}, 5, "" );

my $tus = $runtime_metadata->{tus};
for (@$tus) {
	print STDERR "$_->{filename}, $_->{lines} lines, $_->{inst_sites} inst sites\n";
}

$project->kill();
$project->wait();

$ENV{SCV_VIEWER_SOCKET} = "SCV::Viewer.socket";
# Check that the native test suite can pass with instrumented binaries
is( system("$scv_wrap make -C $tmpdir/vim74/src test"), 0, "make test" );
