use strict;
use SCV::Project;
use SCV::Viewer;
use Test::More tests => 7;
use Time::HiRes qw( time );

#
# This uses tools installed from a package, not the in tree build!
#

my $viewer = SCV::Viewer->new();
my $project = SCV::Project->new();

my $tmpdir = $project->get_tmpdir();

my $vim_src = "ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2";
is( system("cd $tmpdir && curl -O $vim_src"), 0, "download" );
is( system("cd $tmpdir && tar xjf vim-7.4.tar.bz2"), 0, "extract" );

is( system("make -C $tmpdir/vim74/src scratch"), 0, "make scratch" );
# LDADD variable does not get picked up by auto conf, use LIBS instread
is( system("citrun_wrap make -C $tmpdir/vim74/src config LDFLAGS=-L/usr/local/lib LIBS=-lcitrun"), 0, "make config" );
is( system("rm $tmpdir/vim74/src/SRC_NUMBER"), 0, "rm SRC_NUMBER" );
is( system("citrun_wrap make -C $tmpdir/vim74/src myself"), 0, "make myself" );

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

print STDERR ">>> START\n";
# Lets see how long it takes to do 60 data calls
for (1..60) {
	my $data1 = $viewer->get_execution_data($tus);
}
print STDERR ">>> END\n";

$project->kill();
$project->wait();

#$ENV{CITRUN_SOCKET} = "$cwd/SCV::Viewer.socket";
# Check that the native test suite can pass with instrumented binaries
#is( system("make -C $tmpdir/vim74/src test"), 0, "make test" );
