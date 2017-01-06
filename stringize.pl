print "static const char *$ARGV[0] = R\"(";
print while (<STDIN>);
print ")\";";
