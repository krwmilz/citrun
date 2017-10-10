#
# Shared utilities for citrun_gl testing.
# - ok_image, an image diff and show function
#
use Modern::Perl;
use File::Compare;		# compare
use Imager;			# new
use Test::More;			# pass, fail, diag


#
# Compares the image given as the first argument with the image given as the
# second argument and saves the result into the directory given as the third
# argument.
#
# If differences are found, show an ascii art picture of the differences and try
# and launch a graphical viewer too.
#
sub ok_image {
	my $output_file = shift;
	my $output_good = shift;
	my $tmp_dir = shift;

	if (compare( $output_file, $output_good )) {
		my $a = Imager->new( file => $output_good ) or die Imager->errstr;
		my $b = Imager->new( file => $output_file ) or die Imager->errstr;
		my $diff = $a->difference( other => $b );

		my $diff_file = "$tmp_dir/diff.tga";
		$diff->write( file => $diff_file ) or die $diff->errstr;

		# Try and show an ascii art picture of the differences.
		if (open( my $cmd_out, '-|', "img2txt", "-f", "utf8", $diff_file )) {
			diag("diff $diff_file");
			diag("--- t/gl/basic.tga");
			diag("+++ $output_file");
			diag($_) while (<$cmd_out>);
			close( $cmd_out );
		} else {
			die "\\-> Maybe try installing `libcaca`.";
		}

		system("imlib2_view $diff_file");
		#system("xdg-open $diff_file");

		fail( 'is render file identical' );
	}
	else {
		pass( 'is render file identical' );
	}
}

1;
