package test::program;
use strict;
use warnings;

# This module builds the test program when it's used.
system("cd test/program && ../../src/citrun-wrap jam");

1;
