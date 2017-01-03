print "static const char *$ARGV[0] = ";
while (<STDIN>) {
	$_ =~ s/\\/\\\\/g ;
	$_ =~ s/"/\\"/g;
	$_ =~ s/^/"/;
	$_ =~ s/$/\\n"/;
	print ;
}
print ";";
