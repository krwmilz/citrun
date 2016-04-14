use strict;
use Cwd;
use Expect;
use File::Temp qw( tempdir );
use SCV::Viewer;
use Test::More tests => 7;
use Time::HiRes qw( time );

#
# This uses tools installed from a package, not the in tree build!
#

# XXX: check that citrun is installed

my $tmpdir = tempdir( CLEANUP => 1 );
my $vim_src = "ftp://ftp.vim.org/pub/vim/unix/vim-7.4.tar.bz2";
system("cd $tmpdir && curl -O $vim_src") == 0 or die "download failed";
system("cd $tmpdir && tar xjf vim-7.4.tar.bz2") == 0 or die "extract failed";

my $srcdir = "$tmpdir/vim74/src";
system("citrun_wrap make -C $srcdir config") == 0 or die "citrun_wrap make config failed";

# Remove last instrumented node from configure run
system("rm $srcdir/LAST_NODE");
# Make vim and xxd
system("citrun_wrap make -C $srcdir myself") == 0 or die "citrun_wrap make failed";

# Create a new fake viewer to attach the instrumented program to
my $viewer = SCV::Viewer->new();

$ENV{CITRUN_SOCKET} = getcwd . "/SCV::Viewer.socket";
my $exp = Expect->spawn("$srcdir/vim");

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

$exp->hard_close();

# Check that the native test suite can pass with instrumented binaries
$exp = Expect->spawn("make", "-C", "$srcdir/testdir");
$exp->expect(undef, ("ALL DONE"));
